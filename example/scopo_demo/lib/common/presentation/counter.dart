import 'package:flutter/material.dart';

class Counter extends StatelessWidget {
  final String title;
  final int value;
  final void Function() increment;

  const Counter({
    super.key,
    required this.title,
    required this.value,
    required this.increment,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.titleLarge!,
      child: Row(
        children: [
          Text('$title: '),
          Expanded(
              child: Text(
            '$value',
            textAlign: TextAlign.end,
          )),
          IconButton(
            color: Theme.of(context).colorScheme.primary,
            onPressed: increment,
            icon: const Icon(Icons.add_circle),
          ),
        ],
      ),
    );
  }
}
