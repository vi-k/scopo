part of '../scope.dart';

/// A mixin for `State` classes that provides easy access to the scope content.
///
/// ```dart
/// class MyWidget extends StatefulWidget {
///   const MyWidget({super.key});
///
///   @override
///   State<MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget>
///     with ScopeConsumer<MyFeatureScope, MyFeatureDeps, MyFeatureContent> {
///   @override
///   Widget build(BuildContext context) {
///     // Access scope content via `scope`
///     return Text(scope.someValue);
///   }
/// }
/// ```
///
/// Or:
///
/// ```dart
/// typedef MyFeatureConsumer =
///     ScopeConsumer<MyFeatureScope, MyFeatureDeps, MyFeatureContent>;
///
/// class MyWidget extends StatefulWidget {
///   const MyWidget({super.key});
///
///   @override
///   State<MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget> with MyFeatureConsumer {
///   @override
///   Widget build(BuildContext context) {
///     // Access scope content via `scope`
///     return Text(scope.someValue);
///   }
/// }
/// ```
mixin ScopeConsumer<W extends Scope<W, D, S>, D extends ScopeDependencies,
    S extends ScopeState<W, D, S>> {
  S? _scope;
  S get scope => _scope ??= Scope.of<W, D, S>(context);

  V select<V extends Object?>(V Function(S scope) selector) =>
      Scope.select<W, D, S, V>(context, selector);

  BuildContext get context;
}
