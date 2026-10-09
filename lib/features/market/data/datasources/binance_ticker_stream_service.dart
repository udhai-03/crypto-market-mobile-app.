import 'dart:async';
import 'dart:developer';

import 'package:crypto_market_mobile/core/network/binance_api.dart';
import 'package:crypto_market_mobile/core/network/reconnect_backoff.dart';
import 'package:crypto_market_mobile/core/network/web_socket_connection.dart';
import 'package:crypto_market_mobile/features/market/data/models/binance_stream_message.dart';
import 'package:crypto_market_mobile/features/market/domain/models/live_connection_status.dart';

typedef ReconnectTimerFactory = Timer Function(
  Duration delay,
  void Function() callback,
);

/// Streams live 24h ticker events for [symbols] over a single Binance
/// combined-stream WebSocket.
///
/// The socket is opened when [tickerEvents] gets its first listener and
/// closed when the last listener cancels. Dropped connections are retried
/// with exponential backoff until the stream is cancelled or [dispose]d.
class BinanceTickerStreamService {
  BinanceTickerStreamService({
    required List<String> symbols,
    required this._connect,
    this._backoff = const ReconnectBackoff(),
    this._createTimer = Timer.new,
  }) : _uri = BinanceApi.tickerStreamUri(symbols) {
    _events = StreamController<BinanceTickerEvent>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  /// Consecutive failures after which the status is reported as
  /// [LiveConnectionStatus.disconnected] while retries continue.
  static const offlineFailureThreshold = 3;

  static const _logName = 'BinanceTickerStream';

  final Uri _uri;
  final WebSocketConnector _connect;
  final ReconnectBackoff _backoff;
  final ReconnectTimerFactory _createTimer;

  late final StreamController<BinanceTickerEvent> _events;
  final _statusChanges = StreamController<LiveConnectionStatus>.broadcast();

  LiveConnectionStatus _status = LiveConnectionStatus.disconnected;
  WebSocketConnection? _connection;
  StreamSubscription<Object?>? _messageSubscription;
  Timer? _reconnectTimer;

  /// Incremented whenever the current connection is abandoned, so late
  /// callbacks from older connections can be recognised and ignored.
  int _connectionId = 0;
  int _consecutiveFailures = 0;
  bool _active = false;
  bool _disposed = false;

  Stream<BinanceTickerEvent> get tickerEvents => _events.stream;

  LiveConnectionStatus get status => _status;

  /// Emits the current status immediately, then every change.
  Stream<LiveConnectionStatus> get statusChanges {
    return Stream.multi((controller) {
      controller.add(_status);
      final subscription = _statusChanges.stream.listen(
        controller.add,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _active = false;
    _closeConnection();
    _setStatus(LiveConnectionStatus.disconnected);
    unawaited(_events.close());
    unawaited(_statusChanges.close());
  }

  void _start() {
    if (_disposed) return;
    _active = true;
    _consecutiveFailures = 0;
    _setStatus(LiveConnectionStatus.connecting);
    unawaited(_openConnection());
  }

  void _stop() {
    _active = false;
    _closeConnection();
    _setStatus(LiveConnectionStatus.disconnected);
  }

  Future<void> _openConnection() async {
    final connectionId = _connectionId;

    final WebSocketConnection connection;
    try {
      connection = await _connect(_uri);
    } on Object catch (error) {
      if (connectionId != _connectionId) return;
      log('Connection failed', name: _logName, error: error);
      _handleFailure();
      return;
    }

    if (connectionId != _connectionId || !_active) {
      unawaited(connection.close());
      return;
    }

    _connection = connection;
    _setStatus(LiveConnectionStatus.connected);
    _messageSubscription = connection.messages.listen(
      (frame) => _handleFrame(frame, connectionId),
      onError: (Object error) {
        if (connectionId != _connectionId) return;
        log('Connection error', name: _logName, error: error);
        _handleFailure();
      },
      onDone: () {
        if (connectionId != _connectionId) return;
        _handleFailure();
      },
      cancelOnError: true,
    );
  }

  void _handleFrame(Object? frame, int connectionId) {
    if (connectionId != _connectionId) return;

    final BinanceStreamMessage message;
    try {
      message = BinanceStreamMessage.parse(frame);
    } on FormatException catch (error) {
      log('Skipped malformed message', name: _logName, error: error);
      return;
    }

    switch (message) {
      case BinanceTickerEvent():
        _consecutiveFailures = 0;
        _setStatus(LiveConnectionStatus.connected);
        _events.add(message);
      case BinanceServerShutdown():
        _closeConnection();
        _setStatus(LiveConnectionStatus.reconnecting);
        unawaited(_openConnection());
    }
  }

  void _handleFailure() {
    _closeConnection();
    if (!_active) return;

    _consecutiveFailures++;
    _setStatus(
      _consecutiveFailures >= offlineFailureThreshold
          ? LiveConnectionStatus.disconnected
          : LiveConnectionStatus.reconnecting,
    );
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_active || _reconnectTimer != null) return;
    final delay = _backoff.delayFor(_consecutiveFailures - 1);
    _reconnectTimer = _createTimer(delay, () {
      _reconnectTimer = null;
      if (_active) unawaited(_openConnection());
    });
  }

  void _closeConnection() {
    _connectionId++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    unawaited(_messageSubscription?.cancel());
    _messageSubscription = null;
    final connection = _connection;
    _connection = null;
    if (connection != null) unawaited(connection.close());
  }

  void _setStatus(LiveConnectionStatus status) {
    if (_status == status) return;
    _status = status;
    if (!_statusChanges.isClosed) _statusChanges.add(status);
  }
}
