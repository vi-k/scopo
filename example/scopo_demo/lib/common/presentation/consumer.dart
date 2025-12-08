import 'package:flutter/material.dart';

import 'box.dart';

class Consumer extends StatefulWidget {
  final Widget title;
  final List<Widget> description;
  final String Function(BuildContext context) consumerValue;
  final Color blinkingColor;

  const Consumer({
    super.key,
    required this.title,
    required this.description,
    required this.consumerValue,
    required this.blinkingColor,
  });

  @override
  State<Consumer> createState() => _ConsumerState();
}

class _ConsumerState extends State<Consumer> {
  @override
  Widget build(BuildContext context) => Box(
        title: widget.title,
        blinkingColor: widget.blinkingColor,
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodySmall!,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.description,
                  ),
                ),
                VerticalDivider(
                  width: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Text(
                  widget.consumerValue(context),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      );
}
