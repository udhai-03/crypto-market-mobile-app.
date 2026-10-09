import 'dart:async';
import 'dart:io';

/// Minimal WebSocket surface used by streaming services, so tests can
/// replace the real socket with a fake one.
abstract interface class WebSocketConnection {
  /// Incoming frames; completes when the socket closes and errors on failure.
  Stream<Object?> get messages;

  Future<void> close();
}

typedef WebSocketConnector = Future<WebSocketConnection> Function(Uri uri);

class IoWebSocketConnection implements WebSocketConnection {
  IoWebSocketConnection._(this._socket);

  final WebSocket _socket;

  static Future<WebSocketConnection> connect(
    Uri uri, {
    required Duration connectTimeout,
    required Duration pingInterval,
  }) async {
    final client = HttpClient()..connectionTimeout = connectTimeout;
    final pendingSocket = WebSocket.connect(
      uri.toString(),
      customClient: client,
    );

    final WebSocket socket;
    try {
      socket = await pendingSocket.timeout(connectTimeout);
    } on TimeoutException {
      unawaited(
        pendingSocket.then((late) => late.close(), onError: (Object _) {}),
      );
      rethrow;
    }

    socket.pingInterval = pingInterval;
    return IoWebSocketConnection._(socket);
  }

  @override
  Stream<Object?> get messages => _socket;

  @override
  Future<void> close() => _socket.close();
}
