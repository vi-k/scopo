part of '../scope.dart';

/// {@category ScopeModel}
abstract base class ScopeModelCore<
    W extends ScopeModelCore<W, E, M>,
    E extends ScopeModelElementBase<W, E, M>,
    M extends Object> extends ScopeWidgetCore<W, E> {
  const ScopeModelCore({
    super.key,
    super.tag,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  @override
  E createScopeElement();

  static E? maybeOf<W extends ScopeModelCore<W, E, M>,
          E extends ScopeModelElementBase<W, E, M>, M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<W, E>(context, listen: listen);

  static E of<W extends ScopeModelCore<W, E, M>,
          E extends ScopeModelElementBase<W, E, M>, M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<W, E>(context, listen: listen);

  static V select<
          W extends ScopeModelCore<W, E, M>,
          E extends ScopeModelElementBase<W, E, M>,
          M extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(E element) selector,
  ) =>
      ScopeContext.select<W, E, V>(context, selector);
}

/// {@category ScopeModel}
abstract base class ScopeModelElementBase<
        W extends ScopeModelCore<W, E, M>,
        E extends ScopeModelElementBase<W, E, M>,
        M extends Object> extends ScopeWidgetElementBase<W, E>
    implements ScopeModelInheritedElement<W, M> {
  ScopeModelElementBase(super.widget);

  @override
  M get model;

  @override
  void init();

  @override
  void dispose();

  @override
  Widget buildChild();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(MessageProperty('model', '$model'));
  }
}
