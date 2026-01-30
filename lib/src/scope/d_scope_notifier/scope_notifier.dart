part of '../scope.dart';

/// {@category ScopeNotifier}
final class ScopeNotifier<M extends Listenable>
    extends ScopeNotifierBase<ScopeNotifier<M>, M> with _ScopeModelMixin<M> {
  @override
  final Widget Function(BuildContext context) builder;

  const ScopeNotifier({
    super.key,
    super.tag,
    required super.create,
    required super.dispose,
    required this.builder,
  });

  const ScopeNotifier.value({
    super.key,
    required super.value,
    required this.builder,
  }) : super.value();

  static M? maybeOf<M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<ScopeNotifier<M>,
          ScopeModelContext<ScopeNotifier<M>, M>>(
        context,
        listen: listen,
      )?.model;

  static M of<M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<ScopeNotifier<M>, ScopeModelContext<ScopeNotifier<M>, M>>(
        context,
        listen: listen,
      ).model;

  static V select<M extends Listenable, V extends Object?>(
    BuildContext context,
    V Function(M model) selector,
  ) =>
      ScopeContext.select<ScopeNotifier<M>,
          ScopeModelContext<ScopeNotifier<M>, M>, V>(
        context,
        (context) => selector(context.model),
      );
}
