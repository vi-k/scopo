import 'package:flutter/material.dart';

import 'markdown.dart';

class MarkdownBlock extends StatelessWidget {
  final String data;
  final double? fontSize;
  final bool selectable;
  final double indent;

  const MarkdownBlock(
    this.data, {
    super.key,
    this.fontSize,
    this.selectable = false,
    this.indent = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: indent),
      child: Markdown(
        data,
        selectable: selectable,
        fontSize: fontSize,
      ),
    );
  }
}
