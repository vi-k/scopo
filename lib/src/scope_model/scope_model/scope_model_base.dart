part of '../scope_model.dart';

abstract base class ScopeModelBase<W extends ScopeModelBase<W, M>,
        M extends Object>
    extends ScopeModelBottom<W, ScopeModelElement<W, M>, M>
    with _ScopeInheritedWidgetBaseMixin<M> {
  @override
  final M? value;

  @override
  final bool hasValue;

  @override
  final M Function(BuildContext context)? create;

  @override
  final void Function(M model)? dispose;

  const ScopeModelBase({
    super.key,
    required this.create,
    required this.dispose,
  })  : hasValue = false,
        value = null;

  const ScopeModelBase.value({
    super.key,
    required this.value,
  })  : hasValue = true,
        create = null,
        dispose = null;

  @override
  ScopeModelElement<W, M> createScopeElement() => ScopeModelElement(this as W);

  @override
  Widget build(BuildContext context);

  static ScopeModelContext<W, M>?
      maybeOf<W extends ScopeModelBase<W, M>, M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeModelBottom.maybeOf<W, ScopeModelContext<W, M>, M>(
            context,
            listen: listen,
          );

  static ScopeModelContext<W, M>
      of<W extends ScopeModelBase<W, M>, M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeModelBottom.of<W, ScopeModelContext<W, M>, M>(
            context,
            listen: listen,
          );

  static V select<W extends ScopeModelBase<W, M>, M extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeModelContext<W, M> context) selector,
  ) =>
      ScopeModelBottom.select<W, ScopeModelContext<W, M>, M, V>(
        context,
        selector,
      );
}

final class ScopeModelElement<W extends ScopeModelBase<W, M>, M extends Object>
    extends ScopeModelElementBase<W, ScopeModelElement<W, M>, M>
    with _ScopeInheritedElementMixin<W, M> {
  ScopeModelElement(super.widget);
}
