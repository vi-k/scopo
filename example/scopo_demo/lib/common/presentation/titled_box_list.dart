import 'package:flutter/material.dart';

import 'titled_box.dart';

class TitledBoxList extends StatelessWidget {
  final String title;
  final Color titleBackgroundColor;
  final Color titleForegroundColor;
  final Color? blinkingColor;
  final Widget? divider;
  final List<Widget> children;

  const TitledBoxList({
    super.key,
    required this.title,
    required this.titleBackgroundColor,
    required this.titleForegroundColor,
    this.blinkingColor,
    this.divider,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => TitledBox(
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
