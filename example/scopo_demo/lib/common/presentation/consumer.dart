import 'package:flutter/material.dart';

import 'titled_box.dart';

class Consumer extends StatefulWidget {
  final Widget? title;
  final Widget? description;
  final List<Widget>? descriptions;
  final Widget Function(BuildContext context) builder;
  final Color? blinkingColor;

  const Consumer({
    super.key,
    this.title,
    this.description,
    this.descriptions,
    required this.builder,
    this.blinkingColor,
  });

  @override
  State<Consumer> createState() => _ConsumerState();
}

class _ConsumerState extends State<Consumer> {
  @override
  Widget build(BuildContext context) {
    return TitledBox(
      title: widget.title,
      blinkingColor: widget.blinkingColor,
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodySmall!,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                    widget.description ??
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.descriptions ?? [],
                    ),
              ),
              const VerticalDivider(),
              DefaultTextStyle(
                style: Theme.of(context).textTheme.titleSmall!,
                child: widget.builder(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
