import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/core/network/reconnect_backoff.dart';
import 'package:crypto_market_mobile/features/market/data/datasources/binance_ticker_stream_service.dart';
import 'package:crypto_market_mobile/features/market/data/models/binance_stream_message.dart';
import 'package:crypto_market_mobile/features/market/domain/models/live_connection_status.dart';

import '../../../helpers/fake_web_socket.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeWebSocketConnector connector;
  late FakeTimerFactory timers;
  late BinanceTickerStreamService service;
  late List<LiveConnectionStatus> statuses;
  late List<BinanceTickerEvent> events;
  StreamSubscription<BinanceTickerEvent>? eventSubscription;

  setUp(() {
    connector = FakeWebSocketConnector();
    timers = FakeTimerFactory();
    service = BinanceTickerStreamService(
      symbols: const ['BTCUSDT', 'ETHUSDT'],
      connect: connector.call,
      backoff: const ReconnectBackoff(
        initialDelay: Duration(seconds: 1),
        maxDelay: Duration(seconds: 8),
      ),
      createTimer: timers.call,
    );
    statuses = [];
    events = [];
    final statusSubscription = service.statusChanges.listen(statuses.add);
    addTearDown(statusSubscription.cancel);
    addTearDown(service.dispose);
  });

  Future<FakeWebSocketConnection> listenAndConnect() async {
    eventSubscription = service.tickerEvents.listen(events.add);
    final connection = connector.completeNext();
    await flush();
    return connection;
  }

  test('does not connect until someone listens', () async {
    await flush();

    expect(connector.attempts, 0);
    expect(service.status, LiveConnectionStatus.disconnected);
  });

  test('opens one combined-stream connection for all symbols', () async {
    await listenAndConnect();
    final secondListener = service.tickerEvents.listen((_) {});
    addTearDown(secondListener.cancel);
    await flush();

    expect(connector.attempts, 1);
    expect(
      connector.requestedUris.single.toString(),
      'wss://stream.binance.com:9443/stream'
      '?streams=btcusdt@ticker/ethusdt@ticker',
    );
  });

  test('reports connecting then connected', () async {
    await listenAndConnect();

    expect(statuses, [
      LiveConnectionStatus.disconnected,
      LiveConnectionStatus.connecting,
      LiveConnectionStatus.connected,
    ]);
  });

  test('emits parsed ticker events', () async {
    final connection = await listenAndConnect();

    connection.receiveTicker('BTCUSDT', lastPrice: '67000.5');
    connection.receiveTicker('ETHUSDT', lastPrice: '2500');
    await flush();

    expect(events.map((event) => event.symbol), ['BTCUSDT', 'ETHUSDT']);
    expect(events.first.lastPrice, 67000.5);
  });

  test('skips malformed messages and keeps the connection', () async {
    final connection = await listenAndConnect();

    connection
      ..receive('not json')
      ..receive(jsonEncode({'unexpected': true}))
      ..receiveTicker('BTCUSDT');
    await flush();

    expect(events.map((event) => event.symbol), ['BTCUSDT']);
    expect(connection.isClosed, isFalse);
    expect(service.status, LiveConnectionStatus.connected);
    expect(timers.timers, isEmpty);
  });

  test('schedules a reconnect when the server closes the socket', () async {
    final connection = await listenAndConnect();

    connection.dropFromServer();
    await flush();

    expect(service.status, LiveConnectionStatus.reconnecting);
    expect(timers.delays, [const Duration(seconds: 1)]);

    timers.pending!.fire();
    final next = connector.completeNext();
    await flush();
    next.receiveTicker('BTCUSDT');
    await flush();

    expect(connector.attempts, 2);
    expect(service.status, LiveConnectionStatus.connected);
    expect(events, hasLength(1));
  });

  test('schedules a reconnect after a socket error', () async {
    final connection = await listenAndConnect();

    connection.fail(const SocketTestException());
    await flush();

    expect(service.status, LiveConnectionStatus.reconnecting);
    expect(timers.pending, isNotNull);
  });

  test('backs off exponentially up to the maximum delay', () async {
    eventSubscription = service.tickerEvents.listen(events.add);

    for (var attempt = 0; attempt < 5; attempt++) {
      connector.failNext();
      await flush();
      timers.pending!.fire();
    }

    expect(timers.delays, const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 8),
    ]);
  });

  test('reports offline after repeated failures but keeps retrying', () async {
    eventSubscription = service.tickerEvents.listen(events.add);

    for (
      var attempt = 0;
      attempt < BinanceTickerStreamService.offlineFailureThreshold;
      attempt++
    ) {
      connector.failNext();
      await flush();
      if (attempt < BinanceTickerStreamService.offlineFailureThreshold - 1) {
        expect(service.status, LiveConnectionStatus.reconnecting);
        timers.pending!.fire();
      }
    }

    expect(service.status, LiveConnectionStatus.disconnected);
    expect(timers.pending, isNotNull);
  });

  test('resets the backoff after receiving live data', () async {
    eventSubscription = service.tickerEvents.listen(events.add);
    connector.failNext();
    await flush();
    timers.pending!.fire();
    connector.failNext();
    await flush();
    timers.pending!.fire();

    final connection = connector.completeNext();
    await flush();
    connection
      ..receiveTicker('BTCUSDT')
      ..dropFromServer();
    await flush();

    expect(timers.delays.last, const Duration(seconds: 1));
  });

  test('never runs concurrent reconnect attempts', () async {
    final connection = await listenAndConnect();

    connection
      ..fail(const SocketTestException())
      ..dropFromServer();
    await flush();

    expect(timers.timers.where((timer) => timer.isActive), hasLength(1));
    expect(connector.attempts, 1);
  });

  test('ignores events from a replaced connection', () async {
    final oldConnection = await listenAndConnect();
    oldConnection.receive(
      jsonEncode({
        'stream': '!serverShutdown',
        'data': {'e': 'serverShutdown'},
      }),
    );
    await flush();

    expect(service.status, LiveConnectionStatus.reconnecting);
    expect(connector.attempts, 2);
    expect(oldConnection.isClosed, isTrue);

    final newConnection = connector.completeNext();
    await flush();
    oldConnection.receiveTicker('ETHUSDT');
    newConnection.receiveTicker('BTCUSDT');
    await flush();

    expect(events.map((event) => event.symbol), ['BTCUSDT']);
  });

  test('closes a connection that completes after cancellation', () async {
    eventSubscription = service.tickerEvents.listen(events.add);
    await eventSubscription!.cancel();

    final lateConnection = connector.completeNext();
    await flush();

    expect(lateConnection.isClosed, isTrue);
    expect(service.status, LiveConnectionStatus.disconnected);
  });

  test('cancelling the last listener closes the socket and stops '
      'reconnecting', () async {
    final connection = await listenAndConnect();
    connection.dropFromServer();
    await flush();
    final reconnectTimer = timers.pending!;

    await eventSubscription!.cancel();

    expect(reconnectTimer.isActive, isFalse);
    expect(service.status, LiveConnectionStatus.disconnected);
  });

  test('listening again after cancellation reconnects', () async {
    final connection = await listenAndConnect();
    await eventSubscription!.cancel();
    expect(connection.isClosed, isTrue);

    await listenAndConnect();

    expect(connector.attempts, 2);
    expect(service.status, LiveConnectionStatus.connected);
  });

  test('dispose closes everything and ignores later activity', () async {
    final connection = await listenAndConnect();
    var eventsDone = false;
    eventSubscription!.onDone(() => eventsDone = true);

    service.dispose();
    await flush();
    connection.receiveTicker('BTCUSDT');
    await flush();

    expect(connection.isClosed, isTrue);
    expect(eventsDone, isTrue);
    expect(events, isEmpty);
    expect(service.status, LiveConnectionStatus.disconnected);
    expect(timers.timers, isEmpty);
    expect(connector.attempts, 1);
  });
}
