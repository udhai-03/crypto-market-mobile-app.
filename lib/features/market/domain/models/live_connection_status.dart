/// State of the live price connection, independent of the REST snapshot.
enum LiveConnectionStatus {
  /// First connection attempt is in progress.
  connecting,

  /// Receiving live updates.
  connected,

  /// The connection dropped and a reconnect is scheduled or in progress.
  reconnecting,

  /// Not receiving updates: stopped, or reconnects keep failing.
  disconnected,
}
