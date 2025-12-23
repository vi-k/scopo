part of '../scope.dart';

abstract base class ScopeNotifierBase<W extends ScopeNotifierBase<W, M>,
        M extends Listenable>
    extends ScopeNotifierBottom<W, ScopeNotifierElement<W, M>, M>
    with ScopeModelBaseMixin<M> {
  @override
  final M? value;

  @override
  final bool hasValue;

  @override
  final M Function(BuildContext context)? create;

  @override
  final void Function(M model)? dispose;

  const ScopeNotifierBase({
    super.key,
    super.tag,
    required this.create,
    required this.dispose,
  })  : hasValue = false,
        value = null;

  const ScopeNotifierBase.value({
    super.key,
    super.tag,
    required this.value,
  })  : hasValue = true,
        create = null,
        dispose = null;

  @override
  ScopeNotifierElement<W, M> createScopeElement() =>
      ScopeNotifierElement(this as W);

  @override
  Widget build(BuildContext context);

  static ScopeModelContext<W, M>?
      maybeOf<W extends ScopeNotifierBase<W, M>, M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeWidgetContext.maybeOf<W, ScopeModelContext<W, M>>(
            context,
            listen: listen,
          );

  static ScopeModelContext<W, M>
      of<W extends ScopeNotifierBase<W, M>, M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeWidgetContext.of<W, ScopeModelContext<W, M>>(
            context,
            listen: listen,
          );

  static V select<W extends ScopeNotifierBase<W, M>, M extends Listenable,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeModelContext<W, M> context) selector,
  ) =>
      ScopeWidgetContext.select<W, ScopeModelContext<W, M>, V>(
        context,
        selector,
      );
}

final class ScopeNotifierElement<W extends ScopeNotifierBase<W, M>,
        M extends Listenable>
    extends ScopeNotifierElementBase<W, ScopeNotifierElement<W, M>, M>
    with ScopeModelElementMixin<W, M> {
  ScopeNotifierElement(super.widget);

  @override
  void update(W newWidget) {
    if (widget.value != newWidget.value) {
      widget.value?.removeListener(notifyDependents);
      newWidget.value?.removeListener(notifyDependents);
    }
    super.update(newWidget);
  }
}
