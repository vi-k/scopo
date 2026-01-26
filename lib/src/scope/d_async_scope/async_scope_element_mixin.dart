part of '../scope.dart';

base mixin AsyncScopeElementMixin<W extends ScopeInheritedWidget,
        T extends Object?>
    on ParentScopeMixin, ScopeModelInheritedElement<W, AsyncScopeModel<T>> {
  //
  // Overriding block
  //

  Object? get scopeKey => null;

  /// Method must complete [_initCompleter].
  Future<void> _innerInit();

  //
  // End of overriding block
  //

  /// Disposal may begin before the end of asynchronous initialization.
  /// Therefore, we use [_initCompleter] for synchronization.
  final _initCompleter = Completer<void>();

  /// Serves for registration in the parent [ParentScope].
  final _lifecycleCompleter = Completer<void>();

  ExclusiveSequencerEntry? _asyncScopeEntry;

  String get _source => '$W #$hashCode';

  bool get autoSelfDependence => true;

  AsyncScopeState<T> get state => model.state;

  bool get isInitialized => model.state is AsyncScopeReady<T>;

  T get data => switch (model.state) {
        AsyncScopeWaiting() ||
        AsyncScopeProgress() =>
          throw StateError('Not initialized'),
        AsyncScopeReady(:final data) => data,
        AsyncScopeError(:final error, :final stackTrace) =>
          Error.throwWithStackTrace(error, stackTrace),
      };

  T? get dataOrNull => switch (model.state) {
        AsyncScopeWaiting() ||
        AsyncScopeProgress() ||
        AsyncScopeError() =>
          null,
        AsyncScopeReady(:final data) => data,
      };

  bool get hasError => switch (model.state) {
        AsyncScopeWaiting() ||
        AsyncScopeProgress() ||
        AsyncScopeReady() =>
          false,
        AsyncScopeError() => true,
      };

  Object get error => switch (model.state) {
        AsyncScopeWaiting() ||
        AsyncScopeProgress() ||
        AsyncScopeReady() =>
          throw StateError('No error'),
        AsyncScopeError(:final error) => error,
      };

  StackTrace get stackTrace => switch (model.state) {
        AsyncScopeWaiting() ||
        AsyncScopeProgress() ||
        AsyncScopeReady() =>
          throw StateError('No error'),
        AsyncScopeError(:final stackTrace) => stackTrace,
      };

  @override
  void init() {
    super.init();
    // ignore: discarded_futures
    _performAsyncInit();
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    _performAsyncDispose(widget);
    super.dispose();
  }

  Future<void> _performAsyncInit() async {
    assert(model.state is AsyncScopeWaiting);

    _d('init', 'start');

    // Register in parent [ParentScope].
    SchedulerBinding.instance.addPostFrameCallback((_) {
      visitAncestorElements((e) {
        if (e case final ParentScope parent) {
          parent.registerChild(_lifecycleCompleter.future);
          return false;
        }
        return true;
      });
    });

    // Wait for key release.
    if (scopeKey case final scopeKey?) {
      final exclusiveSequencer = ExclusiveSequencer.forKey(scopeKey);
      final entry = exclusiveSequencer.createEntry();
      _asyncScopeEntry = entry;

      _d('init', 'wait for key [$scopeKey] release');
      await entry.enter();
      _d('init', 'key [$scopeKey] released');

      if (!mounted) {
        _d('init', 'cancelled');
        _initCompleter.complete();
        return;
      }
    }

    await _innerInit();
  }

  Future<void> _performAsyncDispose(W widget) async {
    _d('dispose', 'start');

    if (!_initCompleter.isCompleted) {
      _d('dispose', 'wait initialization');
      await _initCompleter.future;
    }

    if (hasChildren) {
      _d(
        'dispose',
        () => 'wait children (count: $childrenCount)',
      );
      await waitForChildren;
    }

    try {
      if (model.state case AsyncScopeReady<T>(:final data)) {
        _d('dispose', 'dispose data');
        await asyncDispose(widget, data);
      } else {
        _d('dispose', 'do not dispose of');
      }

      _d('dispose', 'done');
    } finally {
      _lifecycleCompleter.complete();

      if (_asyncScopeEntry case final asyncScopeEntry?) {
        _d('dispose', 'exit from exclusive sequencer');
        asyncScopeEntry.exit();
      }
    }
  }

  Future<void> asyncDispose(W widget, T data);

  @override
  Widget buildChild() => buildOnState(model.state);

  Widget buildOnState(AsyncScopeState<T> state);

  void _d(String method, Object? message) {
    final messageStr = ScopeLog.objToString(message);
    d(_source, '[$method]${messageStr == null ? '' : ' $messageStr'}');
  }

  void _e(
    String method,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    e(
      () => _source,
      () {
        final messageStr = ScopeLog.objToString(message);
        return '[$method]${messageStr == null ? '' : ' $messageStr'}';
      },
      error: error,
      stackTrace: stackTrace,
    );
  }
}
