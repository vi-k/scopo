part of '../scope.dart';

final class ScopeStateBuilder<S extends Object>
    extends ScopeStateBuilderBase<ScopeStateBuilder<S>, S> {
  final Widget Function(BuildContext context, ScopeStateNotifier<S> notifier)
      builder;

  const ScopeStateBuilder({
    super.key,
    super.tag,
    super.autoSelfDependence = true,
    required super.initialState,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, ScopeStateNotifier<S> notifier) =>
      builder(context, notifier);

  static ScopeStateModel<S>? maybeOf<S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeWidgetContext.maybeOf<ScopeStateBuilder<S>,
          ScopeModelContext<ScopeStateBuilder<S>, ScopeStateModel<S>>>(
        context,
        listen: listen,
      )?.model;

  static ScopeStateModel<S> of<S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeWidgetContext.of<ScopeStateBuilder<S>,
          ScopeModelContext<ScopeStateBuilder<S>, ScopeStateModel<S>>>(
        context,
        listen: listen,
      ).model;

  static S stateOf<S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      listen
          ? ScopeWidgetContext.select<ScopeStateBuilder<S>,
              ScopeModelContext<ScopeStateBuilder<S>, ScopeStateModel<S>>, S>(
              context,
              (context) => context.model.state,
            )
          : ScopeWidgetContext.of<ScopeStateBuilder<S>,
              ScopeModelContext<ScopeStateBuilder<S>, ScopeStateModel<S>>>(
              context,
              listen: false,
            ).model.state;
}
