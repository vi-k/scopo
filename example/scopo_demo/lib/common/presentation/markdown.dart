import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class Markdown extends StatelessWidget {
  final String data;
  final double? fontSize;
  final bool selectable;
  final Color? color;

  const Markdown(
    this.data, {
    super.key,
    this.fontSize,
    this.selectable = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize =
        this.fontSize ?? Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14;
    final content = MarkdownBody(
      data: data,
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        a: TextStyle(fontSize: fontSize),
        p: TextStyle(fontSize: fontSize, color: color),
        h1: TextStyle(
          fontSize: fontSize * 1.3,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        h2: TextStyle(
          fontSize: fontSize * 1.15,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        h3: TextStyle(
          fontSize: fontSize * 1,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        blockSpacing: fontSize / 2,
        em: TextStyle(fontSize: fontSize, color: color),
        strong: TextStyle(fontSize: fontSize, color: color),
        blockquote: TextStyle(fontSize: fontSize, color: color),
        img: TextStyle(fontSize: fontSize, color: color),
        checkbox: TextStyle(fontSize: fontSize, color: color),
        del: TextStyle(fontSize: fontSize, color: color),
        code: TextStyle(
          fontSize: fontSize * .9,
          fontFamily:
              Platform.isIOS || Platform.isMacOS ? 'Menlo' : 'monospace',
          backgroundColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.1),
          color: color,
        ),
        codeblockDecoration: const BoxDecoration(color: Colors.transparent),
        listBulletPadding: EdgeInsets.zero,
        listIndent: fontSize,
        listBullet: TextStyle(fontSize: fontSize, color: color),
      ),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          selectionColor: Colors.blue,
          selectionHandleColor: Colors.amber,
        ),
      ),
      child: selectable ? SelectionArea(child: content) : content,
    );
  }
}
