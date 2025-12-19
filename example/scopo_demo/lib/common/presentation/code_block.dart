import 'package:flutter/material.dart';

import 'code.dart';

class CodeBlock extends StatelessWidget {
  final String code;
  final BorderRadiusGeometry borderRadius;
  final double fontSize;
  final Color? borderColor;

  const CodeBlock(
    this.code, {
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.fontSize = 12,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      // ignore: use_decorated_box
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color:
                borderColor ??
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        child: Code(code, borderRadius: borderRadius, fontSize: fontSize),
      ),
    );
  }
}
