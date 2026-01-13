part of '../scope.dart';

abstract base class ScopeModelBase<W extends ScopeModelBase<W, M>,
        M extends Object> extends ScopeModelCore<W, ScopeModelElement<W, M>, M>
    with ScopeModelBaseMixin<M> {
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
    super.tag,
    required this.create,
    required this.dispose,
  })  : hasValue = false,
        value = null;

  const ScopeModelBase.value({
    super.key,
    super.tag,
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
          ScopeContext.maybeOf<W, ScopeModelContext<W, M>>(
            context,
            listen: listen,
          );

  static ScopeModelContext<W, M>
      of<W extends ScopeModelBase<W, M>, M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.of<W, ScopeModelContext<W, M>>(
            context,
            listen: listen,
          );

  static V select<W extends ScopeModelBase<W, M>, M extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeModelContext<W, M> context) selector,
  ) =>
      ScopeContext.select<W, ScopeModelContext<W, M>, V>(
        context,
        selector,
      );
}

final class ScopeModelElement<W extends ScopeModelBase<W, M>, M extends Object>
    extends ScopeModelElementBase<W, ScopeModelElement<W, M>, M>
    with ScopeModelElementMixin<W, M>
    implements ScopeModelContext<W, M> {
  ScopeModelElement(super.widget);

  Object? get tag => widget.tag;
}
