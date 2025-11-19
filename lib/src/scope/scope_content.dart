part of 'scope.dart';

final class _ScopeContent<
    S extends Scope<S, P, D, C>,
    P extends Object?,
    D extends ScopeDeps,
    C extends ScopeContent<S, P, D, C>> extends StatefulWidget {
  final D deps;
  final C Function() createContent;

  const _ScopeContent({
    required GlobalKey<C> super.key,
    required this.deps,
    required this.createContent,
  });

  @override
  // ignore: no_logic_in_create_state
  State<_ScopeContent<S, P, D, C>> createState() => createContent();

  @override
  String toStringShort() => '$C';
}

abstract base class ScopeContent<S extends Scope<S, P, D, C>, P extends Object?,
        D extends ScopeDeps, C extends ScopeContent<S, P, D, C>>
    extends State<_ScopeContent<S, P, D, C>> {
  @override
  Never get widget => throw UnimplementedError();

  D get deps => super.widget.deps;
}
