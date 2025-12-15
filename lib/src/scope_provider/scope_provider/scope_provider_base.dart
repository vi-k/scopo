part of '../scope_provider.dart';

abstract base class ScopeProviderBase<W extends ScopeProviderBase<W, M>,
        M extends Object>
    extends ScopeProviderBottom<W, ScopeProviderElement<W, M>, M>
    with _ScopeInheritedWidgetBaseMixin<M> {
  @override
  final M? value;

  @override
  final bool hasValue;

  @override
  final M Function(BuildContext context)? create;

  @override
  final void Function(M model)? dispose;

  const ScopeProviderBase({
    super.key,
    required this.create,
    required this.dispose,
  })  : hasValue = false,
        value = null;

  const ScopeProviderBase.value({
    super.key,
    required this.value,
  })  : hasValue = true,
        create = null,
        dispose = null;

  @override
  ScopeProviderElement<W, M> createScopeElement() =>
      ScopeProviderElement(this as W);

  @override
  Widget build(BuildContext context);

  static ScopeContext<W, M>?
      maybeOf<W extends ScopeProviderBase<W, M>, M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeProviderBottom.maybeOf<W, ScopeContext<W, M>, M>(
            context,
            listen: listen,
          );

  static ScopeContext<W, M> of<W extends ScopeProviderBase<W, M>,
          M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeProviderBottom.of<W, ScopeContext<W, M>, M>(context, listen: listen);

  static V select<W extends ScopeProviderBase<W, M>, M extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeContext<W, M> context) selector,
  ) =>
      ScopeProviderBottom.select<W, ScopeContext<W, M>, M, V>(
        context,
        selector,
      );
}

final class ScopeProviderElement<W extends ScopeProviderBase<W, M>,
        M extends Object>
    extends ScopeProviderElementBase<W, ScopeProviderElement<W, M>, M>
    with _ScopeInheritedElementMixin<W, M> {
  ScopeProviderElement(super.widget);
}
