part of '../scope.dart';

final class ScopeModel<M extends Object>
    extends ScopeModelBase<ScopeModel<M>, M> with ScopeModelMixin<M> {
  @override
  final Widget Function(BuildContext context) builder;

  @override
  final String? debugName;

  const ScopeModel({
    super.key,
    required super.create,
    required super.dispose,
    required this.builder,
    this.debugName,
  });

  const ScopeModel.value({
    super.key,
    required super.value,
    required this.builder,
    this.debugName,
  }) : super.value();

  static M? maybeOf<M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeWidgetContext.maybeOf<ScopeModel<M>,
          ScopeModelContext<ScopeModel<M>, M>>(
        context,
        listen: listen,
      )?.model;

  static M of<M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeWidgetContext.of<ScopeModel<M>, ScopeModelContext<ScopeModel<M>, M>>(
        context,
        listen: listen,
      ).model;

  static V select<M extends Object, V extends Object?>(
    BuildContext context,
    V Function(M model) selector,
  ) =>
      ScopeWidgetContext.select<ScopeModel<M>,
          ScopeModelContext<ScopeModel<M>, M>, V>(
        context,
        (context) => selector(context.model),
      );
}
