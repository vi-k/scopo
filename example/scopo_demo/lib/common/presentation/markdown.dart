import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class Markdown extends StatelessWidget {
  final String data;
  final double? fontSize;
  final bool selectable;

  const Markdown(this.data, {super.key, this.fontSize, this.selectable = true});

  @override
  Widget build(BuildContext context) {
    final fontSize =
        this.fontSize ?? Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14;
    final content = MarkdownBody(
      data: data,
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        a: TextStyle(fontSize: fontSize),
        p: TextStyle(fontSize: fontSize),
        h1: TextStyle(fontSize: fontSize * 1.3, fontWeight: FontWeight.bold),
        h2: TextStyle(fontSize: fontSize * 1.15, fontWeight: FontWeight.bold),
        h3: TextStyle(fontSize: fontSize * 1, fontWeight: FontWeight.bold),
        blockSpacing: fontSize / 2,
        em: TextStyle(fontSize: fontSize),
        strong: TextStyle(fontSize: fontSize),
        blockquote: TextStyle(fontSize: fontSize),
        img: TextStyle(fontSize: fontSize),
        checkbox: TextStyle(fontSize: fontSize),
        del: TextStyle(fontSize: fontSize),
        code: TextStyle(
          fontSize: fontSize * .9,
          fontFamily: Platform.isIOS || Platform.isMacOS
              ? 'Menlo'
              : 'monospace',
          backgroundColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        codeblockDecoration: const BoxDecoration(color: Colors.transparent),
        listBulletPadding: EdgeInsets.zero,
        listIndent: fontSize,
        listBullet: TextStyle(fontSize: fontSize),
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
