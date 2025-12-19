import 'package:flutter/material.dart';

class BlinkingBox extends StatefulWidget {
  final Color backgroundColor;
  final Color blinkingColor;
  final Widget child;

  const BlinkingBox({
    super.key,
    this.backgroundColor = Colors.transparent,
    required this.blinkingColor,
    required this.child,
  });

  @override
  State<BlinkingBox> createState() => _BlinkingBoxState();
}

class _BlinkingBoxState extends State<BlinkingBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);
    _restartAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _restartAnimation() {
    _controller
      ..value = 1
      // ignore: discarded_futures
      ..animateTo(0, duration: const Duration(milliseconds: 500));
  }

  @override
  void didUpdateWidget(covariant BlinkingBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _restartAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ColoredBox(
          color:
              Color.lerp(
                widget.backgroundColor,
                widget.blinkingColor,
                _controller.value,
              )!,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
