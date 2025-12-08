part of '../scope_provider.dart';

abstract base class ScopeNotifierBottom<
    W extends ScopeNotifierBottom<W, E, T>,
    E extends ScopeNotifierElementBase<W, E, T>,
    T extends ChangeNotifier> extends ScopeListenableProviderBottom<W, E, T> {
  const ScopeNotifierBottom({
    super.key,
    required super.create,
    super.debugString,
    required super.builder,
  });

  const ScopeNotifierBottom.value({
    super.key,
    required super.value,
    super.debugString,
    required super.builder,
  }) : super.value();

  const ScopeNotifierBottom.raw({
    super.key,
    super.debugString,
    required super.builder,
  }) : super.raw();

  @override
  E createElement();

  static E? maybeGet<
          W extends ScopeNotifierBottom<W, E, T>,
          E extends ScopeNotifierElementBase<W, E, T>,
          T extends ChangeNotifier>(
    BuildContext context,
  ) =>
      ScopeListenableProviderBottom.maybeGet<W, E, T>(context);

  static E get<
          W extends ScopeNotifierBottom<W, E, T>,
          E extends ScopeNotifierElementBase<W, E, T>,
          T extends ChangeNotifier>(
    BuildContext context,
  ) =>
      ScopeListenableProviderBottom.get<W, E, T>(context);

  static E? maybeDepend<
          W extends ScopeNotifierBottom<W, E, T>,
          E extends ScopeNotifierElementBase<W, E, T>,
          T extends ChangeNotifier>(
    BuildContext context,
  ) =>
      ScopeProviderBottom.maybeDepend<W, E, T>(context);

  static E depend<
          W extends ScopeNotifierBottom<W, E, T>,
          E extends ScopeNotifierElementBase<W, E, T>,
          T extends ChangeNotifier>(
    BuildContext context,
  ) =>
      ScopeProviderBottom.depend<W, E, T>(context);

  static V? maybeSelect<
          W extends ScopeNotifierBottom<W, E, T>,
          E extends ScopeNotifierElementBase<W, E, T>,
          T extends ChangeNotifier,
          V extends Object?>(
    BuildContext context,
    V Function(E) selector,
  ) =>
      ScopeListenableProviderBottom.maybeSelect<W, E, T, V>(context, selector);

  static V select<
          W extends ScopeNotifierBottom<W, E, T>,
          E extends ScopeNotifierElementBase<W, E, T>,
          T extends ChangeNotifier,
          V extends Object?>(
    BuildContext context,
    V Function(E) selector,
  ) =>
      ScopeListenableProviderBottom.select<W, E, T, V>(context, selector);

  @override
  String toStringShort() =>
      debugString?.call() ?? '${ScopeNotifierBottom<W, E, T>}';
}

base class ScopeNotifierElementBase<W extends ScopeNotifierBottom<W, E, T>,
        E extends ScopeNotifierElementBase<W, E, T>, T extends ChangeNotifier>
    extends ScopeListenableProviderElementBase<W, E, T> {
  ScopeNotifierElementBase(super.widget);

  @override
  void unmount() {
    super.unmount();
    _model?.dispose();
  }
}
