part of '../scope_provider.dart';

abstract base class ScopeProviderBase<W extends ScopeProviderBase<W, T>,
        T extends Object>
    extends ScopeProviderBottom<W, ScopeProviderElement<W, T>, T> {
  const ScopeProviderBase({
    super.key,
    required super.create,
    super.dispose,
    super.debugString,
    required super.builder,
  });

  const ScopeProviderBase.value({
    super.key,
    required super.value,
    super.debugString,
    required super.builder,
  }) : super.value();

  @override
  ScopeProviderElement<W, T> createElement() => ScopeProviderElement(this as W);

  static ScopeProviderFacade<W, T>? maybeGet<W extends ScopeProviderBase<W, T>,
          T extends Object>(
    BuildContext context,
  ) =>
      ScopeProviderBottom.maybeGet<W, ScopeProviderElement<W, T>, T>(context);

  static ScopeProviderFacade<W, T>
      get<W extends ScopeProviderBase<W, T>, T extends Object>(
    BuildContext context,
  ) =>
          ScopeProviderBottom.get<W, ScopeProviderElement<W, T>, T>(context);

  static ScopeProviderFacade<W, T>?
      maybeDepend<W extends ScopeProviderBase<W, T>, T extends Object>(
    BuildContext context,
  ) =>
          ScopeProviderBottom.maybeDepend<W, ScopeProviderElement<W, T>, T>(
              context);

  static ScopeProviderFacade<W, T>
      depend<W extends ScopeProviderBase<W, T>, T extends Object>(
    BuildContext context,
  ) =>
          ScopeProviderBottom.depend<W, ScopeProviderElement<W, T>, T>(context);

  static V? maybeSelect<W extends ScopeProviderBase<W, T>, T extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeProviderFacade<W, T>) selector,
  ) =>
      ScopeProviderBottom.maybeSelect<W, ScopeProviderElement<W, T>, T, V>(
          context, selector);

  static V select<W extends ScopeProviderBase<W, T>, T extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeProviderFacade<W, T>) selector,
  ) =>
      ScopeProviderBottom.select<W, ScopeProviderElement<W, T>, T, V>(
          context, selector);

  @override
  String toStringShort() => debugString?.call() ?? '${ScopeProviderBase<W, T>}';
}

final class ScopeProviderElement<W extends ScopeProviderBase<W, T>,
        T extends Object>
    extends ScopeProviderElementBase<W, ScopeProviderElement<W, T>, T> {
  ScopeProviderElement(super.widget);
}
