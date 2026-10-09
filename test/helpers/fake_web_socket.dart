import 'dart:async';
import 'dart:convert';

import 'package:crypto_market_mobile/core/network/web_socket_connection.dart';

class FakeWebSocketConnection implements WebSocketConnection {
  final _frames = StreamController<Object?>();
  bool isClosed = false;

  void receive(Object? frame) => _frames.add(frame);

  void receiveTicker(String symbol, {String lastPrice = '100.5'}) {
    receive(tickerFrame(symbol, lastPrice: lastPrice));
  }

  void fail(Object error) => _frames.addError(error);

  void dropFromServer() => unawaited(_frames.close());

  @override
  Stream<Object?> get messages => _frames.stream;

  @override
  Future<void> close() async => isClosed = true;
}

/// Hands out connections in order and records every requested URI.
/// A queued `null` makes that attempt fail.
class FakeWebSocketConnector {
  final requestedUris = <Uri>[];
  final _pending = <Completer<WebSocketConnection>>[];

  int get attempts => requestedUris.length;

  Future<WebSocketConnection> call(Uri uri) {
    requestedUris.add(uri);
    final completer = Completer<WebSocketConnection>();
    _pending.add(completer);
    return completer.future;
  }

  FakeWebSocketConnection completeNext() {
    final connection = FakeWebSocketConnection();
    _pending.removeAt(0).complete(connection);
    return connection;
  }

  void failNext([Object error = const SocketTestException()]) {
    _pending.removeAt(0).completeError(error);
  }
}

class SocketTestException implements Exception {
  const SocketTestException();
}

/// Records scheduled timers instead of waiting on real time.
class FakeTimerFactory {
  final timers = <FakeTimer>[];

  List<Duration> get delays => [for (final timer in timers) timer.delay];

  FakeTimer? get pending {
    final active = timers.where((timer) => timer.isActive);
    return active.isEmpty ? null : active.single;
  }

  Timer call(Duration delay, void Function() callback) {
    final timer = FakeTimer(delay, callback);
    timers.add(timer);
    return timer;
  }
}

class FakeTimer implements Timer {
  FakeTimer(this.delay, this._callback);

  final Duration delay;
  final void Function() _callback;
  bool _active = true;

  void fire() {
    assert(_active);
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

String tickerFrame(String symbol, {String lastPrice = '100.5'}) {
  return jsonEncode({
    'stream': '${symbol.toLowerCase()}@ticker',
    'data': {
      'e': '24hrTicker',
      'E': 1672515782136,
      'C': 1672515782136,
      's': symbol,
      'p': '1.25',
      'P': '2.50',
      'c': lastPrice,
      'h': '110.0',
      'l': '90.0',
      'v': '1000',
      'q': '100500',
    },
  });
}
