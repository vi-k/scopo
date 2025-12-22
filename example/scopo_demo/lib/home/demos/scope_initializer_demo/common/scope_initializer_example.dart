import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../../../common/presentation/expansion.dart';
import '../../../../../../../common/presentation/markdown.dart';
import '../../../../../../common/presentation/consumer.dart';
import '../../../../../../common/presentation/titled_box_list.dart';
import '../../../../common/constants.dart';
import '../../../../common/presentation/blinking_box.dart';
import '../../../../common/presentation/titled_box.dart';
import '../../../../common/utils/string_extensions.dart';

class ScopeInitializerExample extends StatefulWidget {
  final int consumersCount;

  final Widget Function(
    BuildContext context,
    bool withError,
    void Function(String message) log,
  )
  builder;

  const ScopeInitializerExample({
    super.key,
    required this.consumersCount,
    required this.builder,
  });

  @override
  State<ScopeInitializerExample> createState() =>
      _ScopeInitializerExampleState();
}

class _ScopeInitializerExampleState extends State<ScopeInitializerExample> {
  final _counter = ValueNotifier<int>(0);
  var _withError = false;

  void _restart({required bool withError}) {
    _withError = withError;
    _counter.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Expansion(
      initiallyExpanded: true,
      title: const Markdown(Constants.exampleTitle, selectable: false),
      children: [
        Wrap(
          runSpacing: 8,
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ValueListenableBuilder(
              valueListenable: _counter,
              builder: (context, counter, child) {
                final num = counter % widget.consumersCount + 1;
                final next = num % widget.consumersCount + 1;

                return TitledBoxList(
                  title: const Text('Go'),
                  titleBackgroundColor: Theme.of(context).colorScheme.secondary,
                  titleForegroundColor:
                      Theme.of(context).colorScheme.onSecondary,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondary,
                      ),
                      onPressed: () {
                        _restart(withError: false);
                      },
                      child: Text(
                        num < widget.consumersCount
                            ? 'Remove #$num'
                            : 'Restart',
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondary,
                      ),
                      onPressed: () {
                        _restart(withError: true);
                      },
                      child: Text(
                        num < widget.consumersCount
                            ? 'Remove #$num\nand start #$next\nwith error'
                            : 'Restart\nand start #$next\nwith error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
            ValueListenableBuilder(
              valueListenable: _counter,
              builder: (context, value, child) {
                return IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: [
                      for (var i = 0; i < widget.consumersCount; i++)
                        _Consumer(
                          key: ValueKey((value ~/ widget.consumersCount, i)),
                          num: i + 1,
                          isEnabled: value % widget.consumersCount <= i,
                          builder: (context, log) {
                            return widget.builder(context, _withError, log);
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _Consumer extends StatefulWidget {
  final bool isEnabled;
  final Widget Function(BuildContext context, void Function(String message) log)
  builder;
  final int num;

  const _Consumer({
    super.key,
    this.isEnabled = true,
    required this.num,
    required this.builder,
  });

  @override
  State<_Consumer> createState() => _ConsumerState();
}

class _ConsumerState extends State<_Consumer> {
  final _log = ValueNotifier<List<String>>([]);
  var _lastLogBuildedCount = 0;

  @override
  void dispose() {
    _log.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    scheduleMicrotask(() {
      if (_log.value.isEmpty || _log.value.last != message) {
        _log.value = [..._log.value, message];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = Text('Consumer #${widget.num}');

    return !widget.isEnabled
        ? TitledBox(
          title: title,
          child: Center(
            child: Markdown(
              '''
              Removed from widget tree

              **Disposal takes 1 second**
              '''.trimIndent(),
              fontSize: 12,
            ),
          ),
        )
        : Consumer(
          title: title,
          description: ValueListenableBuilder(
            valueListenable: _log,
            builder: (context, value, child) {
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Markdown('**Log:**', fontSize: 12),
                  for (final log in value.take(_lastLogBuildedCount)) Text(log),
                  for (final log in value.skip(_lastLogBuildedCount))
                    BlinkingBox(
                      blinkingColor: Theme.of(context).colorScheme.primary,
                      child: Text(log),
                    ),
                ],
              );

              _lastLogBuildedCount = value.length;
              return content;
            },
          ),
          builder: (context) => widget.builder(context, _addLog),
        );
  }
}
