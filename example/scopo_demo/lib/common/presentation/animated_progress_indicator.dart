import 'package:flutter/material.dart';

class AnimatedProgressIndicator extends StatefulWidget {
  final double? value;
  final Duration stepDuration;
  final Curve curve;
  final Widget Function(double? value) builder;

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
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();

    if (widget.value case final value?) {
      _updateAnimationController(value);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value) {
      _updateAnimationController(widget.value);
    }
  }

  void _updateAnimationController(double? value) {
    if (value == null) {
      _animationController?.dispose();
      _animationController = null;
    } else {
      var animationController = _animationController;
      if (animationController == null) {
        animationController = AnimationController(vsync: this, value: 0);
        _animationController = animationController;
      }

      // ignore: discarded_futures
      animationController.animateTo(
        value,
        duration: widget.stepDuration,
        curve: widget.curve,
      );
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _animationController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_animationController) {
      null => widget.builder(null),
      final AnimationController controller => AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            return widget.builder(controller.value);
          },
        ),
    };
  }
}
