part of '../scope.dart';

final class ScopeNotifier<M extends Listenable>
    extends ScopeNotifierBase<ScopeNotifier<M>, M> with ScopeModelMixin<M> {
  @override
  final Widget Function(BuildContext context) builder;

  @override
  final String? debugName;

  const ScopeNotifier({
    super.key,
    required super.create,
    required super.dispose,
    required this.builder,
    this.debugName,
  });

  const ScopeNotifier.value({
    super.key,
    required super.value,
    required this.builder,
    this.debugName,
  }) : super.value();

  static M? maybeOf<M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeModelBottom.maybeOf<ScopeNotifier<M>,
          ScopeModelContext<ScopeNotifier<M>, M>, M>(
        context,
        listen: listen,
      )?.model;

  static M of<M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeModelBottom.of<ScopeNotifier<M>,
          ScopeModelContext<ScopeNotifier<M>, M>, M>(
        context,
        listen: listen,
      ).model;

  static V select<M extends Listenable, V extends Object?>(
    BuildContext context,
    V Function(M model) selector,
  ) =>
      ScopeModelBottom.select<ScopeNotifier<M>,
          ScopeModelContext<ScopeNotifier<M>, M>, M, V>(
        context,
        (context) => selector(context.model),
      );
}
