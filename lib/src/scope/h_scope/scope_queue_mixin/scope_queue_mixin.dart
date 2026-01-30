part of '../../scope.dart';

/// {@category Scope}
typedef ScopeQueueStream<T extends ScopeDependencies>
    = Stream<ScopeInitState<ScopeQueueProgress, T>>;

/// {@category Scope}
base mixin ScopeQueueMixin<T extends ScopeDependencies> on ScopeDependencies {
  List<List<ScopeDependencyBase>>? _queue;

  String _buildMessage(String method, Object? message) {
    final text = ScopeLog.objToString(message);
    return '[$method]${text == null ? '' : ' $text'}';
  }

  void _d(String method, [Object? message]) {
    d(
      () => '$T(#${shortHash(this)})',
      () => _buildMessage(method, message),
    );
  }

  void _i(String method, [Object? message]) {
    i(
      () => '$T(#${shortHash(this)})',
      () => _buildMessage(method, message),
    );
  }

  void _e(
    String method,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    e(
      () => '$T(#$hashCode)',
      () => _buildMessage(method, message),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Build the queue of dependencies.
  List<List<ScopeDependencyBase>> buildQueue(BuildContext context);

  /// Initialize the scope dependencies.
  ScopeQueueStream<T> init(BuildContext context) async* {
    final streamController = StreamController<ScopeQueueProgress>();
    var isInitialized = false;

    try {
      _i('init');

      final queue = _queue ??= buildQueue(context);
      final count = queue.fold<int>(0, (p, e) => p + e.length);
      final progressIterator = ProgressIterator(count);

      // ignore: unawaited_futures
      Future<void>(() async {
        List<ScopeDependencyBase>? lastGroup;

        try {
          for (final (index, group) in queue.indexed) {
            _d('init', () => 'group $index');

            final futures = <Future<void>>[];

            for (final dep in group) {
              lastGroup = group;

              switch (dep._callInit()) {
                case final Future<void> future:
                  futures.add(
                    future.then((_) {
                      final progress = ScopeQueueProgress(
                        dep.name,
                        progressIterator.nextStep(),
                      );
                      _d('init', progress);
                      streamController.add(progress);
                    }),
                  );

                default:
                  final progress = ScopeQueueProgress(
                    dep.name,
                    progressIterator.nextStep(),
                  );
                  _d('init', progress);
                  streamController.add(progress);
              }
            }

            if (futures.isNotEmpty) {
              await futures.wait;
            }
          }
        } on Object catch (error, stackTrace) {
          streamController.addError(error, stackTrace);
        } finally {
          if (lastGroup != null) {
            // Print errors.
            for (final dep in lastGroup) {
              if (dep._state
                  case _ScopeDependencyStateInitializationFailed(
                    :final error,
                    :final stackTrace,
                  )) {
                _e('init', dep, error: error, stackTrace: stackTrace);
              }
            }
          }

          await streamController.close();
        }
      });

      yield* streamController.stream.map(ScopeProgress.new);

      yield ScopeReady(this as T);
      isInitialized = true;
      _i('init', 'done');
    } on Object catch (e, s) {
      _e('init', 'failed', error: e, stackTrace: s);
    } finally {
      if (!isInitialized) {
        _i('init', 'cancelled');
        await dispose();
      }
    }
  }

  @override
  Future<void> dispose() async {
    final queue = _queue;
    if (queue == null) {
      return;
    }

    _i('dispose', '(in reverse order)');

    for (var i = queue.length - 1; i >= 0; i--) {
      final group = queue[i];
      _d('dispose', () => 'group $i');

      try {
        await group.map((e) => e._callDispose()).whereType<Future<void>>().wait;
        // ignore: avoid_catching_errors
      } on Object {
        // noop
      }

      // Print result.
      for (final dep in group) {
        switch (dep._state) {
          case _ScopeDependencyStateDisposalFailed(
              :final error,
              :final stackTrace,
            ):
            _e('dispose', dep, error: error, stackTrace: stackTrace);

          default:
            _d('dispose', dep);
        }
      }
    }

    _i('dispose', 'done');
  }
}
