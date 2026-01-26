import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../../utils/console/console.dart';

final class ScreenDependencies extends ScopeDependencies
    with ScopeQueueMixin<ScreenDependencies> {
  ScreenDependencies();

  @override
  List<List<ScopeDependencyBase>> buildQueue(BuildContext context) => [
        [
          ScopeDependency(
            '1',
            () async {
              console.log(ScreenScope, 'initialize 1');
              await Future<void>.delayed(const Duration(milliseconds: 200));
            },
            onDispose: () async {
              console.log(ScreenScope, 'dispose 1');
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
          ),
        ],
        [
          ScopeDependency(
            '2',
            () async {
              console.log(ScreenScope, 'initialize 2');
              await Future<void>.delayed(const Duration(milliseconds: 200));
            },
            onDispose: () async {
              console.log(ScreenScope, 'dispose 2');
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
          ),
        ],
        [
          ScopeDependency(
            '3',
            () async {
              console.log(ScreenScope, 'initialize 3');
              await Future<void>.delayed(const Duration(milliseconds: 200));
            },
            onDispose: () async {
              console.log(ScreenScope, 'dispose 3');
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
          ),
        ],
        [
          ScopeDependency(
            '4',
            () async {
              console.log(ScreenScope, 'initialize 4');
              await Future<void>.delayed(const Duration(milliseconds: 200));
            },
            onDispose: () async {
              console.log(ScreenScope, 'dispose 4');
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
          ),
        ],
      ];
}

final class ScreenScope
    extends Scope<ScreenScope, ScreenDependencies, ScreenState> {
  const ScreenScope({
    super.key,
    super.scopeKey,
  }) : super(pauseAfterInitialization: const Duration(milliseconds: 200));

  static ScreenState of(BuildContext context) =>
      Scope.of<ScreenScope, ScreenDependencies, ScreenState>(context);

  @override
  Stream<ScopeInitState<ScopeQueueProgress, ScreenDependencies>>
      initDependencies(
    BuildContext context,
  ) =>
          ScreenDependencies().init(context);

  Widget _page({required Widget child}) {
    return Scaffold(
      appBar: AppBar(title: const Text('screen scope')),
      body: child,
    );
  }

  @override
  Widget buildOnInitializing(
    BuildContext context,
    covariant ScopeQueueProgress? progress,
  ) {
    return _page(
      child: Center(
        child: Text(
          'Initializing'
          '${progress == null ? '' : ' ${progress.number}/${progress.total}'}',
        ),
      ),
    );
  }

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    covariant ScopeQueueProgress? progress,
  ) {
    return _page(
      child: Center(
        child: Text(
          'Error${progress == null ? '' : ' on step $progress'}: $error',
        ),
      ),
    );
  }

  @override
  Widget wrapState(
    BuildContext context,
    ScreenDependencies dependencies,
    Widget child,
  ) =>
      NavigationNode(
        onPop: (context, result) async {
          console.log(ScreenScope, 'close');
          await ScreenScope.of(context).close();
          console.log(ScreenScope, 'closed');
          return true;
        },
        child: _page(
          child: child,
        ),
      );

  @override
  ScreenState createState() => ScreenState();

  @override
  Widget Function(BuildContext context)? get buildOnClosing {
    return (context) => ColoredBox(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'This is a screenshot',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        );
  }
}

final class ScreenState
    extends ScopeState<ScreenScope, ScreenDependencies, ScreenState> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 200,
        child: Stack(
          children: [
            Positioned.fill(
              child: Transform.flip(
                flipX: true,
                child: const CircularProgressIndicator(),
              ),
            ),
            const Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            ),
            Center(
              child: FilledButton(
                onPressed: Navigator.of(context).maybePop,
                child: const Text('close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
