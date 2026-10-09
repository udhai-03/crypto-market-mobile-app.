import 'package:flutter/material.dart';

/// Fades and lifts [child] into place once, after a delay based on [index]
/// so sibling items appear in a short cascade.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.animate = true,
  });

  final Widget child;
  final int index;

  /// When false the child is shown in place immediately.
  final bool animate;

  static const Duration _duration = Duration(milliseconds: 380);
  static const Duration _stagger = Duration(milliseconds: 45);

  /// Later items share the last delay so long lists don't feel slow.
  static const int _maxStaggeredItems = 8;
  static const double _offsetY = 0.12;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final delay =
        FadeSlideIn._stagger *
        widget.index.clamp(0, FadeSlideIn._maxStaggeredItems);
    final total = delay + FadeSlideIn._duration;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _progress,
      child: SlideTransition(
        position: _progress.drive(
          Tween(begin: const Offset(0, FadeSlideIn._offsetY), end: Offset.zero),
        ),
        child: widget.child,
      ),
    );
  }
}
