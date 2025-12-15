import 'package:flutter/material.dart';

import 'blinking_box.dart';

class Box extends StatelessWidget {
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? blinkingColor;
  final EdgeInsetsGeometry contentPadding;
  final Widget child;

  const Box({
    super.key,
    this.borderColor,
    this.backgroundColor,
    this.foregroundColor,
    this.blinkingColor,
    this.contentPadding = const EdgeInsets.all(8),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: contentPadding, child: child);
    if (blinkingColor case final blinkingColor?) {
      content = BlinkingBox(blinkingColor: blinkingColor, child: content);
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              borderColor ??
              backgroundColor ??
              Theme.of(context).colorScheme.primary,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(context).style.copyWith(
          color: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
        ),
        child: content,
      ),
    );
  }
}
