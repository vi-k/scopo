import 'package:flutter/material.dart';
import 'package:scopo_demo/common/presentation/blinking_box.dart';

class Box extends StatelessWidget {
  final Widget title;
  final Color? titleBackgroundColor;
  final Color? titleForegroundColor;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? blinkingColor;
  final EdgeInsetsGeometry contentPadding;
  final Widget child;

  const Box({
    super.key,
    required this.title,
    this.titleBackgroundColor,
    this.titleForegroundColor,
    this.backgroundColor,
    this.foregroundColor,
    this.blinkingColor,
    this.contentPadding = const EdgeInsets.all(8),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final titleBackgroundColor =
        this.titleBackgroundColor ?? Theme.of(context).colorScheme.primary;
    Widget content = Padding(
      padding: contentPadding,
      child: child,
    );
    if (blinkingColor case final blinkingColor?) {
      content = BlinkingBox(
        blinkingColor: blinkingColor,
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: titleBackgroundColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        defaultColumnWidth: IntrinsicColumnWidth(),
        children: [
          TableRow(
            children: [
              ColoredBox(
                color: titleBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 8,
                  ),
                  child: DefaultTextStyle(
                    style: DefaultTextStyle.of(context).style.copyWith(
                          color: titleForegroundColor ??
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                    child: Center(child: title),
                  ),
                ),
              ),
            ],
          ),
          TableRow(children: [
            DefaultTextStyle(
              style: DefaultTextStyle.of(context).style.copyWith(
                    color: foregroundColor ??
                        Theme.of(context).colorScheme.onSurface,
                  ),
              child: content,
            )
          ]),
        ],
      ),
    );
  }
}
