import 'package:flutter/material.dart';

import '../../../utils/console/console_view.dart';
import 'stream_scope_example1.dart';
import 'stream_scope_example2.dart';
import 'stream_scope_example3.dart';

class StreamScopeDemo extends StatefulWidget {
  const StreamScopeDemo({super.key});

  @override
  State<StreamScopeDemo> createState() => _StreamScopeDemoState();
}

class _StreamScopeDemoState extends State<StreamScopeDemo> {
  var _rebuildCounter = 0;

  void _rebuild() {
    setState(() {
      _rebuildCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodySmall!,
      child: Column(
        children: [
          Expanded(
            child: StreamScopeExample1(
              key: ValueKey(_rebuildCounter),
            ),
          ),
          const Expanded(
            child: ConsoleView(source: StreamScopeExample1),
          ),
          Expanded(
            child: StreamScopeExample2(
              key: ValueKey(_rebuildCounter),
            ),
          ),
          const Expanded(
            child: ConsoleView(source: StreamScopeExample2),
          ),
          Expanded(
            child: StreamScopeExample3(
              key: ValueKey(_rebuildCounter),
            ),
          ),
          const Expanded(
            child: ConsoleView(source: StreamScopeExample3),
          ),
          _RebuildButton(rebuild: _rebuild),
        ],
      ),
    );
  }
}

class _RebuildButton extends StatelessWidget {
  final void Function() rebuild;

  const _RebuildButton({required this.rebuild});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FilledButton(
        onPressed: rebuild,
        child: const Text('Restart page'),
      ),
    );
  }
}
