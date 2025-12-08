part of '../scope_provider.dart';

final class ScopeNotifier<T extends ChangeNotifier>
    extends ScopeNotifierBase<ScopeNotifier<T>, T> {
  const ScopeNotifier({
    super.key,
    required super.create,
    super.debugString,
    required super.builder,
  });

  const ScopeNotifier.value({
    super.key,
    required super.value,
    super.debugString,
    required super.builder,
  }) : super.value();

  static T? maybeGet<T extends ChangeNotifier>(
    BuildContext context,
  ) =>
      ScopeNotifierBase.maybeGet<ScopeNotifier<T>, T>(context)?.model;

  static T get<T extends ChangeNotifier>(
    BuildContext context,
  ) =>
      ScopeNotifierBase.get<ScopeNotifier<T>, T>(context).model;

  static T? maybeDepend<T extends ChangeNotifier>(
    BuildContext context,
  ) =>
      ScopeNotifierBase.maybeDepend<ScopeNotifier<T>, T>(context)?.model;

  static T depend<T extends ChangeNotifier>(
    BuildContext context,
  ) =>
      ScopeNotifierBase.depend<ScopeNotifier<T>, T>(context).model;

  static V? maybeSelect<T extends ChangeNotifier, V extends Object?>(
    BuildContext context,
    V Function(T) selector,
  ) =>
      ScopeNotifierBase.maybeSelect<ScopeNotifier<T>, T, V>(
          context, (f) => selector(f.model));

  static V select<T extends ChangeNotifier, V extends Object?>(
    BuildContext context,
    V Function(T) selector,
  ) =>
      ScopeNotifierBase.select<ScopeNotifier<T>, T, V>(
          context, (f) => selector(f.model));

  @override
  String toStringShort() => debugString?.call() ?? '${ScopeNotifier<T>}';
}
