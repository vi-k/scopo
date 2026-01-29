part of '../scope.dart';

abstract base class LiteScopeCore<
    W extends LiteScopeCore<W, E, S>,
    E extends LiteScopeElementBase<W, E, S>,
    S extends LiteScopeCoreState<W, E, S>> extends AsyncScopeCore<W, E> {
  const LiteScopeCore({
    super.key,
    super.tag,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  @override
  InheritedElement createScopeElement();

  static W paramsOf<
          W extends LiteScopeCore<W, E, S>,
          E extends LiteScopeElementBase<W, E, S>,
          S extends LiteScopeCoreState<W, E, S>>(
    BuildContext context, {
    required bool listen,
  }) =>
      listen
          ? ScopeContext.select<W, LiteScopeElementBase<W, E, S>, W>(
              context,
              (element) => element.widget,
            )
          : ScopeContext.of<W, LiteScopeElementBase<W, E, S>>(
              context,
              listen: false,
            ).widget;

  static V selectParam<
          W extends LiteScopeCore<W, E, S>,
          E extends LiteScopeElementBase<W, E, S>,
          S extends LiteScopeCoreState<W, E, S>,
          V extends Object?>(
    BuildContext context,
    V Function(W widget) selector,
  ) =>
      ScopeContext.select<W, LiteScopeElementBase<W, E, S>, V>(
        context,
        (element) => selector(element.widget),
      );

  static S? maybeOf<
          W extends LiteScopeCore<W, E, S>,
          E extends LiteScopeElementBase<W, E, S>,
          S extends LiteScopeCoreState<W, E, S>>(
    BuildContext context,
  ) =>
      ScopeContext.maybeOf<W, LiteScopeElementBase<W, E, S>>(
        context,
        listen: false,
      )?._globalStateKey.currentState;

  static S of<
          W extends LiteScopeCore<W, E, S>,
          E extends LiteScopeElementBase<W, E, S>,
          S extends LiteScopeCoreState<W, E, S>>(
    BuildContext context,
  ) =>
      ScopeContext.of<W, LiteScopeElementBase<W, E, S>>(
        context,
        listen: false,
      )._globalStateKey.currentState!;

  static V select<
          W extends LiteScopeCore<W, E, S>,
          E extends LiteScopeElementBase<W, E, S>,
          S extends LiteScopeCoreState<W, E, S>,
          V extends Object?>(
    BuildContext context,
    V Function(S scope) selector,
  ) =>
      ScopeContext.select<W, LiteScopeElementBase<W, E, S>, V>(
        context,
        (element) => selector(element._globalStateKey.currentState!),
      );
}

abstract base class LiteScopeElementBase<
    W extends LiteScopeCore<W, E, S>,
    E extends LiteScopeElementBase<W, E, S>,
    S extends LiteScopeCoreState<W, E, S>> extends AsyncScopeElementBase<W, E> {
  var _autoSelfDependence = true;
  final _globalStateKey = GlobalKey<S>();
  S? _state;
  Completer<void>? _closeCompleter;
  Completer<void>? _screenshotCompleter;

  LiteScopeElementBase(super.widget);

  //
  // Overriding block
  //

  @override
  Stream<AsyncScopeInitState> initAsync();

  Widget? buildOnWaiting();

  Widget buildOnInitializing(Object? progress);

  Widget buildOnError(
    Object error,
    StackTrace stackTrace,
    Object? progress,
  );

  S createState();

  Widget wrapState(Widget child) => child;

  Widget? buildOnClosing() => null;

  //
  // End of overriding block
  //

  @override
  @mustCallSuper
  Future<void> disposeAsync() async {
    if (_state case final state?) {
      await state._performAsyncDispose();
    }
  }

  @override
  bool get autoSelfDependence => _autoSelfDependence;

  @override
  Widget buildOnState(AsyncScopeState state) => switch (state) {
        AsyncScopeWaiting() => buildOnWaiting() ?? buildOnInitializing(null),
        AsyncScopeProgress(:final progress) => buildOnInitializing(progress),
        AsyncScopeReady() => buildOnReady(),
        AsyncScopeError(:final error, :final stackTrace, :final progress) =>
          buildOnError(error, stackTrace, progress),
      };

  @mustCallSuper
  Widget buildOnReady() {
    _autoSelfDependence = false;

    final child = wrapState(
      _LiteScopeCoreWidget<W, E, S>(
        key: _globalStateKey,
        createState: _createState,
      ),
    );

    return switch (_screenshotCompleter) {
      null => child,
      final screenshotCompleter => Stack(
          children: [
            ScreenshotReplacer(
              onCompleted: () {
                if (!screenshotCompleter.isCompleted) {
                  screenshotCompleter.complete();
                }
              },
              child: child,
            ),
            Positioned.fill(
              child: buildOnClosing() ??
                  ColoredBox(
                    color: Theme.of(this)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.8),
                    child: const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
            ),
          ],
        ),
    };
  }

  S _createState() => _state = createState().._scopeElement = this as E;

  @override
  Future<void> _performAsyncDispose() async {
    if (_closeCompleter case final closeCompleter?) {
      return closeCompleter.future;
    }

    final closeCompleter = Completer<void>();
    _closeCompleter = closeCompleter;

    markNeedsBuild();

    if (_screenshotCompleter case final screenshotCompleter?) {
      await screenshotCompleter.future;
    }

    try {
      await super._performAsyncDispose();
    } finally {
      closeCompleter.complete();
    }
  }

  /// Закрывает скоуп до вызова dispose.
  ///
  /// Даёт возможность показать экран закрытия скоупа, заменяя содержимое
  /// виджета скриншотом.
  Future<void> close() async {
    _screenshotCompleter = Completer<void>();
    await _performAsyncDispose();
  }
}

final class _LiteScopeCoreWidget<
    W extends LiteScopeCore<W, E, S>,
    E extends LiteScopeElementBase<W, E, S>,
    S extends LiteScopeCoreState<W, E, S>> extends StatefulWidget {
  final S Function() _createState;

  const _LiteScopeCoreWidget({
    required GlobalKey<S> super.key,
    required S Function() createState,
  }) : _createState = createState;

  @override
  S createState() => _createState();

  @override
  String toStringShort() => '$S';
}

abstract base class LiteScopeCoreState<
        W extends LiteScopeCore<W, E, S>,
        E extends LiteScopeElementBase<W, E, S>,
        S extends LiteScopeCoreState<W, E, S>>
    extends State<_LiteScopeCoreWidget<W, E, S>> {
  //
  // Overriding block
  //

  FutureOr<void> initAsync() {}

  FutureOr<void> disposeAsync() {}

  @override
  Widget build(BuildContext context);

  //
  // End of overriding block
  //

  final _initCompleter = Completer<void>();
  late final E _scopeElement;

  @override
  @visibleForTesting
  Never get widget => throw UnimplementedError();

  W get params => _scopeElement.widget;

  bool get isInitialized => _initCompleter.isCompleted;

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    _performAsyncInit(); // ignore: discarded_futures
  }

  Future<void> _performAsyncInit() async {
    final result = initAsync();
    if (result is Future<void>) {
      await result;
      _initCompleter.complete();
      if (mounted) {
        onInitialized();
        notifyDependents();
      }
    } else {
      SchedulerBinding.instance.runOutsideFrame(() {
        _initCompleter.complete();
        if (mounted) {
          onInitialized();
          notifyDependents();
        }
      });
    }
  }

  Future<void> _performAsyncDispose() async {
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }

    final result = disposeAsync();
    if (result is Future<void>) {
      await result;
    }
  }

  void onInitialized() {}

  @mustCallSuper
  void notifyDependents() {
    _scopeElement.notifyDependents();
  }

  Future<void> close() => ScopeContext.of<W, E>(context, listen: false).close();
}
