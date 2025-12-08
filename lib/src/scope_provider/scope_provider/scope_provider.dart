part of '../scope_provider.dart';

final class ScopeProvider<T extends Object>
    extends ScopeProviderBase<ScopeProvider<T>, T> {
  const ScopeProvider({
    super.key,
    required super.create,
    super.dispose,
    super.debugString,
    required super.builder,
  });

  const ScopeProvider.value({
    super.key,
    required super.value,
    super.debugString,
    required super.builder,
  }) : super.value();

  static T? maybeGet<T extends Object>(
    BuildContext context,
  ) =>
      ScopeProviderBase.maybeGet<ScopeProvider<T>, T>(context)?.model;

  static T get<T extends Object>(
    BuildContext context,
  ) =>
      ScopeProviderBase.get<ScopeProvider<T>, T>(context).model;

  static T? maybeDepend<T extends Object>(
    BuildContext context,
  ) =>
      ScopeProviderBase.maybeDepend<ScopeProvider<T>, T>(context)?.model;

  static T depend<T extends Object>(
    BuildContext context,
  ) =>
      ScopeProviderBase.depend<ScopeProvider<T>, T>(context).model;

  static V? maybeSelect<T extends Object, V extends Object?>(
    BuildContext context,
    V Function(T) selector,
  ) =>
      ScopeProviderBase.maybeSelect<ScopeProvider<T>, T, V>(
          context, (f) => selector(f.model));

  static V select<T extends Object, V extends Object?>(
    BuildContext context,
    V Function(T) selector,
  ) =>
      ScopeProviderBase.select<ScopeProvider<T>, T, V>(
          context, (f) => selector(f.model));

  @override
  String toStringShort() => debugString?.call() ?? '${ScopeProvider<T>}';
}
