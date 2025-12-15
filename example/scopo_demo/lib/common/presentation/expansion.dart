import 'package:flutter/material.dart';

class Expansion extends StatelessWidget {
  final Widget title;
  final Color? borderColor;
  final Color? titleBackgroundColor;
  final Color? contentBackgroundColor;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry contentPadding;
  final List<Widget> children;

  const Expansion({
    super.key,
    required this.title,
    this.borderColor,
    this.titleBackgroundColor,
    this.contentBackgroundColor,
    this.initiallyExpanded = false,
    this.contentPadding = const EdgeInsets.all(8),
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: ExpansionTile(
      title: title,
      dense: true,
      initiallyExpanded: initiallyExpanded,
      maintainState: true,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: borderColor ?? Theme.of(context).colorScheme.primary,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      collapsedShape: RoundedRectangleBorder(
        side: BorderSide(
          color: borderColor ?? Theme.of(context).colorScheme.primary,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      collapsedBackgroundColor:
          titleBackgroundColor ??
          Theme.of(context).colorScheme.surfaceContainerHighest,
      backgroundColor:
          titleBackgroundColor ??
          Theme.of(context).colorScheme.surfaceContainerHighest,
      children: [
        Container(
          color:
              contentBackgroundColor ??
              Theme.of(context).colorScheme.surfaceContainer,
          padding: contentPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    ),
  );
}
