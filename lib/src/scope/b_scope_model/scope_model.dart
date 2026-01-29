part of '../scope.dart';

final class ScopeModel<M extends Object>
    extends ScopeModelBase<ScopeModel<M>, M> with ScopeModelMixin<M> {
  @override
  final Widget Function(BuildContext context) builder;

  const ScopeModel({
    super.key,
    super.tag,
    required super.create,
    required super.dispose,
    required this.builder,
  });

  const ScopeModel.value({
    super.key,
    super.tag,
    required super.value,
    required this.builder,
  }) : super.value();

  static M? maybeOf<M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<ScopeModel<M>, ScopeModelContext<ScopeModel<M>, M>>(
        context,
        listen: listen,
      )?.model;

  static M of<M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<ScopeModel<M>, ScopeModelContext<ScopeModel<M>, M>>(
        context,
        listen: listen,
      ).model;

  static V select<M extends Object, V extends Object?>(
    BuildContext context,
    V Function(M model) selector,
  ) =>
      ScopeContext.select<ScopeModel<M>, ScopeModelContext<ScopeModel<M>, M>,
          V>(
        context,
        (context) => selector(context.model),
      );
}
