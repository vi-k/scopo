import 'package:flutter/material.dart';

import 'code.dart';
import 'expansion.dart';

class ExpansionCode extends StatelessWidget {
  final Widget title;
  final Color? borderColor;
  final Color? titleBackgroundColor;
  final Color? contentBackgroundColor;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry contentPadding;
  final String code;
  final double fontSize;

  const ExpansionCode(
    this.code, {
    super.key,
    required this.title,
    this.borderColor,
    this.titleBackgroundColor,
    this.contentBackgroundColor,
    this.initiallyExpanded = false,
    this.contentPadding = EdgeInsets.zero,
    this.fontSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return Expansion(
      title: title,
      borderColor: borderColor,
      titleBackgroundColor: titleBackgroundColor,
      contentBackgroundColor: contentBackgroundColor,
      initiallyExpanded: initiallyExpanded,
      contentPadding: contentPadding,
      children: [
        Code(code, borderRadius: BorderRadius.zero, fontSize: fontSize),
      ],
    );
  }
}
