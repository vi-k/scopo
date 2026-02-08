part of '../../scope.dart';

/// {@category Scope}
typedef ScopeAutoDependenciesStream<T extends ScopeDependencies>
    = Stream<ScopeInitState<ScopeAutoDependenciesProgress, T>>;

/// {@category Scope}
abstract base class ScopeAutoDependencies<T extends ScopeDependencies,
    C extends Object?> implements ScopeDependencies {
  bool get autoDisposeOnError => true;

  ScopeDependency get root =>
      _root ?? (throw StateError('dependencies not built'));
  ScopeDependency? _root;

  /// Build the queue of dependencies.
  ScopeDependency buildDependencies(C context);

  /// Initialize the scope dependencies.
  Stream<ScopeInitState<ScopeAutoDependenciesProgress, T>> init(
    C context,
  ) async* {
    final dependencies = _root ??= this.buildDependencies(context);
    final progressIterator = ProgressIterator(dependencies.count);

    try {
      print(T);
      yield* dependencies.runInit().map((path) {
        final step = progressIterator.nextStep();
        _d('init', '$path ($step)');
        return ScopeProgress(ScopeAutoDependenciesProgress(path, step));
      });

      if (dependencies.isInitialized) {
        yield ScopeReady(this as T);
      }
    } finally {
      print('$T finally');
      if (!dependencies.isInitialized && autoDisposeOnError) {
        await dispose();
      }
      // autoDisposeOnError
    }
  }

  @override
  Future<void> dispose() async {
    final dependencies = _root;
    if (dependencies == null) {
      return;
    }

    _i('dispose');

    final completer = Completer<void>();

    dependencies.runDispose().listen(
      (dep) {
        print('disposed: $dep');
      },
      onError: (Object e) {},
      onDone: completer.complete,
      cancelOnError: false,
    );

    await completer.future;

    _i('dispose', 'done');
  }

  ScopeDependency dep(String name, FutureOr<void> Function(DepHelper) init) =>
      ScopeDependency(name, init);

  ScopeDependency sequential(
    String name,
    Iterable<ScopeDependency> dependencies,
  ) =>
      ScopeDependency.sequential(name, dependencies);

  ScopeDependency concurrent(
    String name,
    Iterable<ScopeDependency> dependencies,
  ) =>
      ScopeDependency.concurrent(name, dependencies);

  Iterable<ScopeDependencyInfo> flattenDependencies() sync* {
    yield* _extract(root, 0, '');
  }

  Iterable<ScopeDependencyInfo> _extract(
    ScopeDependency dependency,
    int level,
    String path,
  ) sync* {
    yield ScopeDependencyInfo(level: level, path: path, dependency: dependency);
    switch (dependency) {
      case ScopeDependencyGroup():
        for (final child in dependency.dependencies) {
          yield* _extract(child, level + 1, '$path${dependency.name}/');
        }
      case ScopeDependency():
      // no-op
    }
  }

  Iterable<ScopeDependencyInfo> flattenDependenciesWithErrors() =>
      flattenDependencies().where(
        (info) => switch (info.dependency.state) {
          final _ScopeDependencyWithErrors state =>
            state.errors().any((e) => e.error is! ScopeDependencyException),
          ScopeDependencySuccessStates() => false,
        },
      );

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
}

final class ScopeDependencyInfo {
  final int level;
  final String path;
  final ScopeDependency dependency;

  const ScopeDependencyInfo({
    required this.level,
    required this.path,
    required this.dependency,
  });

  String indent([String indent = '  ']) => indent * level;

  @override
  String toString() =>
      '${indent()}${dependency.wrappedName} ${dependency.stateToString()}';
}
