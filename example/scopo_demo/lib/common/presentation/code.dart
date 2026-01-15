import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_syntax_view/flutter_syntax_view.dart';

class Code extends StatelessWidget {
  final String code;
  final BorderRadiusGeometry borderRadius;
  final double fontSize;

  const Code(
    this.code, {
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final fontFamily =
        Platform.isIOS || Platform.isMacOS ? 'Menlo' : 'monospace';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: borderRadius,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: SyntaxView(
          syntax: Syntax.DART,
          syntaxTheme: switch (Theme.of(context).brightness) {
            Brightness.dark => SyntaxTheme.vscodeDark(),
            Brightness.light => SyntaxTheme.vscodeLight(),
          }
              .copyWith(
            baseStyle: TextStyle(fontFamily: fontFamily),
            backgroundColor: Colors.transparent,
          ),
          fontSize: fontSize,
          withZoom: false,
          withLinesCount: false,
          code: code,
        ),
      ),
    );
  }
}
