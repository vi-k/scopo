import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../common/presentation/animated_progress_indicator.dart';
import '../../../../common/presentation/box.dart';
import '../../../common/scope_initializer_example.dart';

class ScopeStreamInitializerExample extends StatelessWidget {
  const ScopeStreamInitializerExample({
    super.key,
  });

  @override
  Widget build(BuildContext context) => ScopeInitializerExample(
        consumersCount: 4,
        builder: (context, withError, log) => ScopeStreamInitializer<int>(
          init: () async* {
            const step = Duration(milliseconds: 200);
            final progress = DoubleProgressIterator(count: 4);

            while (true) {
              final nextProgress = progress.nextProgress();
              await Future<void>.delayed(step);
              yield ScopeProgressV2(nextProgress);
              if (withError && nextProgress == 1.0) {
                // ignore: only_throw_errors
                throw 'test error';
              }
              if (nextProgress >= 1.0) break;
            }

            await Future<void>.delayed(step);
            yield const ScopeReadyV2(42);
          },
          dispose: (_) async {
            await Future<void>.delayed(
              const Duration(seconds: 1),
            );
          },
          buildOnWaitingForPrevious: (context) {
            log('onWaitingForPrevious');
            return const Box(
              child: Icon(Icons.lock_clock),
            );
          },
          buildOnInitializing: (context, progress) {
            log('onInitializing: $progress');
            return Box(
              child: SizedBox.square(
                dimension: 24,
                child: AnimatedProgressIndicator(
                  value: progress is double ? progress : null,
                  stepDuration: const Duration(milliseconds: 300),
                  builder: (value) => CircularProgressIndicator(
                    value: value,
                  ),
                ),
              ),
            );
          },
          buildOnReady: (context, value) {
            log('onReady: $value');
            return Box(
              child: SizedBox.square(
                dimension: 24,
                child: Center(
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
          buildOnError: (context, error, stackTrace) {
            log('onError');
            return Box(
              borderColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.error,
              child: Text('$error'),
            );
          },
        ),
      );
}
