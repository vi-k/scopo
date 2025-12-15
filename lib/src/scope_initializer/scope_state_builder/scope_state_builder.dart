part of '../scope_initializer.dart';

final class ScopeStateBuilder<S extends Object>
    extends ScopeStateBuilderBase<ScopeStateBuilder<S>, S> {
  final Widget Function(BuildContext context, ScopeStateNotifier<S> notifier)
      builder;

  const ScopeStateBuilder({
    super.key,
    super.selfDependence = true,
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
      ScopeProviderBottom.maybeOf<
          ScopeStateBuilder<S>,
          ScopeContext<ScopeStateBuilder<S>, ScopeStateModel<S>>,
          ScopeStateModel<S>>(
        context,
        listen: listen,
      )?.model;

  static ScopeStateModel<S> of<S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeProviderBottom.of<
          ScopeStateBuilder<S>,
          ScopeContext<ScopeStateBuilder<S>, ScopeStateModel<S>>,
          ScopeStateModel<S>>(
        context,
        listen: listen,
      ).model;

  static S? maybeStateOf<S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeProviderBottom.maybeOf<
          ScopeStateBuilder<S>,
          ScopeContext<ScopeStateBuilder<S>, ScopeStateModel<S>>,
          ScopeStateModel<S>>(
        context,
        listen: listen,
      )?.model.state;

  static S stateOf<S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeProviderBottom.of<
          ScopeStateBuilder<S>,
          ScopeContext<ScopeStateBuilder<S>, ScopeStateModel<S>>,
          ScopeStateModel<S>>(
        context,
        listen: listen,
      ).model.state;
}
