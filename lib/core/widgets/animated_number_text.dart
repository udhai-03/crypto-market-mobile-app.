import 'package:flutter/material.dart';

/// Text that counts up to [value] when first shown; later changes are
/// applied in place so frequent live updates don't keep the number moving.
class AnimatedNumberText extends StatefulWidget {
  const AnimatedNumberText({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  final double value;
  final String Function(double value) format;
  final TextStyle? style;

  static const Duration _duration = Duration(milliseconds: 700);

  @override
  State<AnimatedNumberText> createState() => _AnimatedNumberTextState();
}

class _AnimatedNumberTextState extends State<AnimatedNumberText> {
  bool _introDone = false;

  @override
  Widget build(BuildContext context) {
    if (_introDone || MediaQuery.disableAnimationsOf(context)) {
      return _text(widget.value);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widget.value),
      duration: AnimatedNumberText._duration,
      curve: Curves.easeOutCubic,
      onEnd: () => setState(() => _introDone = true),
      builder: (context, current, _) => _text(current),
    );
  }

  Widget _text(double value) => Text(
    widget.format(value),
    maxLines: 1,
    style: (widget.style ?? const TextStyle()).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}
