part of '../scope_provider.dart';

abstract base class ScopeNotifierBase<W extends ScopeNotifierBase<W, T>,
        T extends ChangeNotifier>
    extends ScopeNotifierBottom<W, ScopeNotifierElement<W, T>, T> {
  const ScopeNotifierBase({
    super.key,
    required super.create,
    super.debugString,
    required super.builder,
  });

  const ScopeNotifierBase.value({
    super.key,
    required super.value,
    super.debugString,
    required super.builder,
  }) : super.value();

  @override
  ScopeNotifierElement<W, T> createElement() =>
      ScopeNotifierElement<W, T>(this as W);

  static ScopeProviderFacade<W, T>?
      maybeGet<W extends ScopeNotifierBase<W, T>, T extends ChangeNotifier>(
    BuildContext context,
  ) =>
          ScopeListenableProviderBottom.maybeGet<W, ScopeNotifierElement<W, T>,
              T>(context);

  static ScopeProviderFacade<W, T>
      get<W extends ScopeNotifierBase<W, T>, T extends ChangeNotifier>(
    BuildContext context,
  ) =>
          ScopeListenableProviderBottom.get<W, ScopeNotifierElement<W, T>, T>(
              context);

  static ScopeProviderFacade<W, T>?
      maybeDepend<W extends ScopeNotifierBase<W, T>, T extends ChangeNotifier>(
    BuildContext context,
  ) =>
          ScopeListenableProviderBottom.maybeDepend<W,
              ScopeNotifierElement<W, T>, T>(context);

  static ScopeProviderFacade<W, T>
      depend<W extends ScopeNotifierBase<W, T>, T extends ChangeNotifier>(
    BuildContext context,
  ) =>
          ScopeListenableProviderBottom.depend<W, ScopeNotifierElement<W, T>,
              T>(context);

  static V? maybeSelect<W extends ScopeNotifierBase<W, T>,
          T extends ChangeNotifier, V extends Object?>(
    BuildContext context,
    V Function(ScopeProviderFacade<W, T>) selector,
  ) =>
      ScopeListenableProviderBottom.maybeSelect<W, ScopeNotifierElement<W, T>,
          T, V>(context, selector);

  static V select<W extends ScopeNotifierBase<W, T>, T extends ChangeNotifier,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeProviderFacade<W, T>) selector,
  ) =>
      ScopeListenableProviderBottom.select<W, ScopeNotifierElement<W, T>, T, V>(
          context, selector);

  @override
  String toStringShort() => debugString?.call() ?? '${ScopeNotifierBase<W, T>}';
}

final class ScopeNotifierElement<W extends ScopeNotifierBase<W, T>,
        T extends ChangeNotifier>
    extends ScopeNotifierElementBase<W, ScopeNotifierElement<W, T>, T> {
  ScopeNotifierElement(super.widget);
}
