part of '../scope_provider.dart';

final class ScopeListenableProvider<T extends Listenable>
    extends ScopeListenableProviderBase<ScopeListenableProvider<T>, T> {
  const ScopeListenableProvider({
    super.key,
    required super.create,
    super.dispose,
    super.debugString,
    required super.builder,
  });

  const ScopeListenableProvider.value({
    super.key,
    required super.value,
    super.debugString,
    required super.builder,
  }) : super.value();

  static T? maybeGet<T extends Listenable>(
    BuildContext context,
  ) =>
      ScopeListenableProviderBase.maybeGet<ScopeListenableProvider<T>, T>(
              context)
          ?.model;

  static T get<T extends Listenable>(
    BuildContext context,
  ) =>
      ScopeListenableProviderBase.get<ScopeListenableProvider<T>, T>(context)
          .model;

  static T? maybeDepend<T extends Listenable>(
    BuildContext context,
  ) =>
      ScopeListenableProviderBase.maybeDepend<ScopeListenableProvider<T>, T>(
              context)
          ?.model;

  static T depend<T extends Listenable>(
    BuildContext context,
  ) =>
      ScopeListenableProviderBase.depend<ScopeListenableProvider<T>, T>(context)
          .model;

  static V? maybeSelect<T extends Listenable, V extends Object?>(
    BuildContext context,
    V Function(T) selector,
  ) =>
      ScopeListenableProviderBase.maybeSelect<ScopeListenableProvider<T>, T, V>(
          context, (f) => selector(f.model));

  static V select<T extends Listenable, V extends Object?>(
    BuildContext context,
    V Function(T) selector,
  ) =>
      ScopeListenableProviderBase.select<ScopeListenableProvider<T>, T, V>(
          context, (f) => selector(f.model));

  @override
  String toStringShort() =>
      debugString?.call() ?? '${ScopeListenableProvider<T>}';
}
