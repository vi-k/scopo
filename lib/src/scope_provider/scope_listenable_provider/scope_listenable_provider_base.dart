part of '../scope_provider.dart';

abstract base class ScopeListenableProviderBase<
        W extends ScopeListenableProviderBase<W, T>, T extends Listenable>
    extends ScopeListenableProviderBottom<W,
        ScopeListenableProviderElement<W, T>, T> {
  const ScopeListenableProviderBase({
    super.key,
    required super.create,
    super.dispose,
    super.debugString,
    required super.builder,
  });

  const ScopeListenableProviderBase.value({
    super.key,
    required super.value,
    super.debugString,
    required super.builder,
  }) : super.value();

  @override
  ScopeListenableProviderElement<W, T> createElement() =>
      ScopeListenableProviderElement(this as W);

  static ScopeProviderFacade<W, T>? maybeGet<
          W extends ScopeListenableProviderBase<W, T>, T extends Listenable>(
    BuildContext context,
  ) =>
      ScopeListenableProviderBottom.maybeGet<W,
          ScopeListenableProviderElement<W, T>, T>(context);

  static ScopeProviderFacade<W, T>
      get<W extends ScopeListenableProviderBase<W, T>, T extends Listenable>(
    BuildContext context,
  ) =>
          ScopeListenableProviderBottom.get<W,
              ScopeListenableProviderElement<W, T>, T>(context);

  static ScopeProviderFacade<W, T>? maybeDepend<
          W extends ScopeListenableProviderBase<W, T>, T extends Listenable>(
    BuildContext context,
  ) =>
      ScopeListenableProviderBottom.maybeDepend<W,
          ScopeListenableProviderElement<W, T>, T>(context);

  static ScopeProviderFacade<W, T>
      depend<W extends ScopeListenableProviderBase<W, T>, T extends Listenable>(
    BuildContext context,
  ) =>
          ScopeListenableProviderBottom.depend<W,
              ScopeListenableProviderElement<W, T>, T>(context);

  static V? maybeSelect<W extends ScopeListenableProviderBase<W, T>,
          T extends Listenable, V extends Object?>(
    BuildContext context,
    V Function(ScopeProviderFacade<W, T>) selector,
  ) =>
      ScopeListenableProviderBottom.maybeSelect<W,
          ScopeListenableProviderElement<W, T>, T, V>(context, selector);

  static V select<W extends ScopeListenableProviderBase<W, T>,
          T extends Listenable, V extends Object?>(
    BuildContext context,
    V Function(ScopeProviderFacade<W, T>) selector,
  ) =>
      ScopeListenableProviderBottom.select<W,
          ScopeListenableProviderElement<W, T>, T, V>(context, selector);

  @override
  String toStringShort() =>
      debugString?.call() ?? '${ScopeListenableProviderBase<W, T>}';
}

final class ScopeListenableProviderElement<
        W extends ScopeListenableProviderBase<W, T>, T extends Listenable>
    extends ScopeListenableProviderElementBase<W,
        ScopeListenableProviderElement<W, T>, T> {
  ScopeListenableProviderElement(super.widget);
}
