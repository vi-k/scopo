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
  late final ScopeElement<W, D, S> _scopeElement;

  @mustCallSuper
  void notifyDependents() {
    _scopeElement.notifyDependents();
  }

  ChangeNotifier? _notifier;

  @override
  Never get widget => throw UnimplementedError();

  W get params => _scopeElement.widget;

  D get dependencies => _scopeElement.value;

  Future<void> close() async {
    // +++
    // await Scope._stateOf<W, T, C>(context)?._close();
  }

  @mustCallSuper
  @override
  void dispose() {
    _notifier?.dispose();
    super.dispose();
  }
}
