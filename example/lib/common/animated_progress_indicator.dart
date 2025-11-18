import 'package:flutter/material.dart';

class AnimatedProgressIndicator extends StatefulWidget {
  final double value;
  final Duration stepDuration;
  final Curve curve;
  final Widget Function(double value) builder;

  const AnimatedProgressIndicator({
    super.key,
    required this.value,
    this.stepDuration = const Duration(milliseconds: 500),
    this.curve = Curves.fastOutSlowIn,
    required this.builder,
  });

  @override
  State<AnimatedProgressIndicator> createState() =>
      _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this)..animateTo(
      widget.value,
      duration: widget.stepDuration,
      curve: widget.curve,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value) {
      _animationController
        ..stop()
        ..animateTo(
          widget.value,
          duration: widget.stepDuration,
          curve: widget.curve,
        );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animationController,
    builder: (_, _) => widget.builder(_animationController.value),
  );
}
