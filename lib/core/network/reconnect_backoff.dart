import 'dart:math' as math;

/// Exponential reconnect delay: initial, 2x, 4x, ... capped at [maxDelay].
class ReconnectBackoff {
  const ReconnectBackoff({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
  });

  final Duration initialDelay;
  final Duration maxDelay;

  static const int _maxExponent = 20;

  /// [attempt] is zero-based: 0 is the first retry.
  Duration delayFor(int attempt) {
    final exponent = attempt.clamp(0, _maxExponent);
    final delayMs = initialDelay.inMilliseconds * math.pow(2, exponent);
    return Duration(
      milliseconds: math.min(delayMs.toInt(), maxDelay.inMilliseconds),
    );
  }
}
