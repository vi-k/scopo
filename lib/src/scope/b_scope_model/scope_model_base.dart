part of '../scope.dart';

abstract base class ScopeModelBase<W extends ScopeModelBase<W, M>,
        M extends Object>
    extends ScopeModelBottom<W, ScopeModelElement<W, M>, M>
    with ScopeModelBaseMixin<M> {
  @override
  final String? tag;

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
    this.tag,
    required this.create,
    required this.dispose,
  })  : hasValue = false,
        value = null;

  const ScopeModelBase.value({
    super.key,
    this.tag,
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
          ScopeWidgetContext.maybeOf<W, ScopeModelContext<W, M>>(
            context,
            listen: listen,
          );

  static ScopeModelContext<W, M>
      of<W extends ScopeModelBase<W, M>, M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeWidgetContext.of<W, ScopeModelContext<W, M>>(
            context,
            listen: listen,
          );

  static V select<W extends ScopeModelBase<W, M>, M extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeModelContext<W, M> context) selector,
  ) =>
      ScopeWidgetContext.select<W, ScopeModelContext<W, M>, V>(
        context,
        selector,
      );
}

final class ScopeModelElement<W extends ScopeModelBase<W, M>, M extends Object>
    extends ScopeModelElementBase<W, ScopeModelElement<W, M>, M>
    with ScopeModelElementMixin<W, M>
    implements ScopeModelContext<W, M> {
  ScopeModelElement(super.widget);

  String? get tag => widget.tag;
}
