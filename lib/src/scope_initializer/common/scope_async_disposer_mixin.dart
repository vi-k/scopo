part of '../scope_initializer.dart';

mixin ScopeAsyncDisposerElementMixin<W extends ScopeInheritedWidget,
        T extends Object?>
    on ScopeInheritedElement<W, ScopeStateModel<ScopeInitializerState<T>>> {
  static final _staticLifecycleCompleters = <(Type, Key?), Completer<void>>{};

  final _initCompleter = Completer<void>();
  final _lifecycleCompleter = Completer<void>();
  late final (Type, Key?) _completerKey = (W, _disposeKey);

  Key? get _disposeKey;

  Duration? get _disposeTimeout;

  void Function()? get _onDisposeTimeout;

  @override
  void init() {
    super.init();
    // ignore: discarded_futures
    runInitAsync();
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    runDisposeAsync(widget);
    super.dispose();
  }

  @mustCallSuper
  Future<void> runInitAsync() async {
    assert(model.state is ScopeInitializerWaitingForPrevious);

    while (true) {
      final previousLifecycleCompleter =
          _staticLifecycleCompleters[_completerKey];
      if (previousLifecycleCompleter == null) {
        break;
      }
      try {
        var future = previousLifecycleCompleter.future;
        if (_disposeTimeout case final timeout?) {
          future = future.timeout(timeout);
        }
        await future;
      } on TimeoutException {
        if (mounted) {
          _onDisposeTimeout?.call();
          // В случае зависания предыдущего необходимо не допустить
          // одновременный запуск всех, кто ждал завершения. Запускаем их по
          // одному в порядке очереди.
          final currentLifecycleCompleter =
              _staticLifecycleCompleters[_completerKey];
          if (currentLifecycleCompleter == null ||
              identical(
                currentLifecycleCompleter,
                previousLifecycleCompleter,
              )) {
            break;
          }
        }
      }
      if (!mounted) break;
    }
    if (!mounted) return;

    _staticLifecycleCompleters[_completerKey] = _lifecycleCompleter;
  }

  Future<void> runDisposeAsync(W widget) async {
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }

    try {
      if (model.state case ScopeReadyV2<T>(:final value)) {
        final f = disposeAsync(widget, value);
        if (f is Future<void>) {
          await f;
        }
      }
    } finally {
      final currentCompleter = _staticLifecycleCompleters[_completerKey];
      if (identical(currentCompleter, _lifecycleCompleter)) {
        _staticLifecycleCompleters.remove(_completerKey);
      }
      _lifecycleCompleter.complete();
    }
  }

  FutureOr<void> disposeAsync(W widget, T value);

  @override
  Widget buildBranch() => buildState(model.state);

  Widget buildState(ScopeInitializerState<T> state);
}
