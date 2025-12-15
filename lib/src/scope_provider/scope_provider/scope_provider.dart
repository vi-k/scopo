part of '../scope_provider.dart';

final class ScopeProvider<M extends Object>
    extends ScopeProviderBase<ScopeProvider<M>, M>
    with _ScopeInheritedWidgetMixin<M> {
  @override
  final Widget Function(BuildContext context) builder;

  @override
  final String? debugName;

  const ScopeProvider({
    super.key,
    required super.create,
    required super.dispose,
    required this.builder,
    this.debugName,
  });

  const ScopeProvider.value({
    super.key,
    required super.value,
    required this.builder,
    this.debugName,
  }) : super.value();

  static M? maybeOf<M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeProviderBottom.maybeOf<ScopeProvider<M>,
          ScopeContext<ScopeProvider<M>, M>, M>(
        context,
        listen: listen,
      )?.model;

  static M of<M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeProviderBottom.of<ScopeProvider<M>,
          ScopeContext<ScopeProvider<M>, M>, M>(
        context,
        listen: listen,
      ).model;

  static V select<M extends Object, V extends Object?>(
    BuildContext context,
    V Function(M model) selector,
  ) =>
      ScopeProviderBottom.select<ScopeProvider<M>,
          ScopeContext<ScopeProvider<M>, M>, M, V>(
        context,
        (context) => selector(context.model),
      );
}
