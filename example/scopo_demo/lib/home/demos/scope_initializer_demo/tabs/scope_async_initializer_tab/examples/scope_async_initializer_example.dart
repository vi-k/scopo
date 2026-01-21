import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../../../../common/presentation/box.dart';
import '../../../common/scope_initializer_example.dart';

class ScopeAsyncInitializerExample extends StatelessWidget {
  const ScopeAsyncInitializerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopeInitializerExample(
      consumersCount: 3,
      builder: (context, withError, log) {
        return ScopeAsyncInitializer<int>(
          exclusiveCoordinatorKey: const ValueKey('scope_async_initializer'),
          init: (context) async {
            await Future<void>.delayed(const Duration(seconds: 2));
            if (withError) {
              // ignore: only_throw_errors
              throw 'test error';
            }
            return 42;
          },
          dispose: (_) async {
            await Future<void>.delayed(const Duration(seconds: 1));
          },
          buildOnWaitingForPrevious: (context) {
            log('onWaitingForPrevious');
            return const Box(child: Icon(Icons.lock_clock));
          },
          buildOnInitializing: (context) {
            log('onInitializing');
            return const Box(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(),
              ),
            );
          },
          buildOnReady: (context, value) {
            log('onReady: $value');
            return Box(
              child: SizedBox.square(
                dimension: 24,
                child: Center(
                  child: Text('$value', textAlign: TextAlign.center),
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
        );
      },
    );
  }
}
