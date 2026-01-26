part of '../scope.dart';

final class _ScopeStateWidget<
    W extends Scope<W, D, S>,
    D extends ScopeDependencies,
    S extends ScopeState<W, D, S>> extends StatefulWidget {
  final S Function() _createState;

  const _ScopeStateWidget({
    required GlobalKey<S> super.key,
    required S Function() createState,
  }) : _createState = createState;

  @override
  State<_ScopeStateWidget<W, D, S>> createState() => _createState();

  @override
  String toStringShort() => '$S';
}

abstract base class ScopeState<
    W extends Scope<W, D, S>,
    D extends ScopeDependencies,
    S extends ScopeState<W, D, S>> extends State<_ScopeStateWidget<W, D, S>> {
  //
  // Overriding block
  //

  FutureOr<void> asyncInit() {}
  Future<void> asyncDispose() async {}

  //
  // End of overriding block
  //

  final _initCompleter = Completer<void>();
  late final ScopeElement<W, D, S> _scopeElement;
  ChangeNotifier? _notifier;

  @override
  @visibleForTesting
  Never get widget => throw UnimplementedError();

  W get params => _scopeElement.widget;

  D get dependencies => _scopeElement.data;

  bool get isInitialized => _initCompleter.isCompleted;

  Future<void> get whenIsInitialized => _initCompleter.future;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _performAsyncInit();
  }

  @mustCallSuper
  @override
  void dispose() {
    _notifier?.dispose();
    super.dispose();
  }

  Future<void> _performAsyncInit() {
    final result = asyncInit();
    if (result is Future<void>) {
      return result.whenComplete(_initCompleter.complete);
    } else {
      _initCompleter.complete();
      return Future<void>.value();
    }
  }

  Future<void> _performAsyncDispose() async {
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }

    await asyncDispose();
  }

  @mustCallSuper
  void notifyDependents() {
    _scopeElement.notifyDependents();
  }

  Future<void> close() =>
      ScopeContext.of<W, ScopeElement<W, D, S>>(context, listen: false).close();
}
