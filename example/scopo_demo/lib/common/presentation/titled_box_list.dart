import 'package:flutter/material.dart';

import 'titled_box.dart';

class TitledBoxList extends StatelessWidget {
  final Widget title;
  final Color titleBackgroundColor;
  final Color titleForegroundColor;
  final Color? blinkingColor;
  final double spacing;
  final List<Widget> children;

  const TitledBoxList({
    super.key,
    required this.title,
    required this.titleBackgroundColor,
    required this.titleForegroundColor,
    this.blinkingColor,
    this.spacing = 8,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return TitledBox(
      title: title,
      titleBackgroundColor: titleBackgroundColor,
      titleForegroundColor: titleForegroundColor,
      blinkingColor: blinkingColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing,
        children: children,
      ),
    );
  }
}
