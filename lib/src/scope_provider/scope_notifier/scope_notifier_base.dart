part of '../scope_provider.dart';

abstract base class ScopeNotifierBase<W extends ScopeNotifierBase<W, M>,
        M extends Listenable>
    extends ScopeNotifierBottom<W, ScopeNotifierElement<W, M>, M>
    with _ScopeInheritedWidgetBaseMixin<M> {
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
    required this.create,
    required this.dispose,
  })  : hasValue = false,
        value = null;

  const ScopeNotifierBase.value({
    super.key,
    required this.value,
  })  : hasValue = true,
        create = null,
        dispose = null;

  @override
  ScopeNotifierElement<W, M> createScopeElement() =>
      ScopeNotifierElement(this as W);

  @override
  Widget build(BuildContext context);

  static ScopeContext<W, M>?
      maybeOf<W extends ScopeNotifierBase<W, M>, M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeProviderBottom.maybeOf<W, ScopeContext<W, M>, M>(
            context,
            listen: listen,
          );

  static ScopeContext<W, M> of<W extends ScopeNotifierBase<W, M>,
          M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeProviderBottom.of<W, ScopeContext<W, M>, M>(context, listen: listen);

  static V select<W extends ScopeNotifierBase<W, M>, M extends Listenable,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeContext<W, M> context) selector,
  ) =>
      ScopeProviderBottom.select<W, ScopeContext<W, M>, M, V>(
        context,
        selector,
      );
}

final class ScopeNotifierElement<W extends ScopeNotifierBase<W, M>,
        M extends Listenable>
    extends ScopeNotifierElementBase<W, ScopeNotifierElement<W, M>, M>
    with _ScopeInheritedElementMixin<W, M> {
  ScopeNotifierElement(super.widget);

  @override
  void update(W newWidget) {
    if (widget.value != newWidget.value) {
      widget.value?.removeListener(_listener);
      newWidget.value?.removeListener(_listener);
    }
    super.update(newWidget);
  }
}
