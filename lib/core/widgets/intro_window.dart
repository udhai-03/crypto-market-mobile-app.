/// Tracks the short period after a list first appears, so only items built
/// during that period play an entrance animation. Items built later (while
/// scrolling, sorting, or filtering) appear in place without motion.
class IntroWindow {
  IntroWindow() : _clock = Stopwatch()..start();

  static const Duration _length = Duration(milliseconds: 700);

  final Stopwatch _clock;

  bool get isOpen => _clock.elapsed < _length;
}
