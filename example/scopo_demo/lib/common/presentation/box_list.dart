import 'package:flutter/material.dart';

import 'box.dart';

class BoxList extends StatelessWidget {
  final String title;
  final Color titleBackgroundColor;
  final Color titleForegroundColor;
  final Color? blinkingColor;
  final Widget? divider;
  final List<Widget> children;

  const BoxList({
    super.key,
    required this.title,
    required this.titleBackgroundColor,
    required this.titleForegroundColor,
    this.blinkingColor,
    this.divider,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Box(
      title: Text(title),
      titleBackgroundColor: titleBackgroundColor,
      titleForegroundColor: titleForegroundColor,
      blinkingColor: blinkingColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: children,
      ),
    );
  }
}
