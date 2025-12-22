// import 'package:flutter/widgets.dart';

// import 'scope.dart';
// import 'scope_deps.dart';

// /// A mixin for `State` classes that provides easy access to the scope content.
// ///
// /// ```dart
// /// class MyWidget extends StatefulWidget {
// ///   const MyWidget({super.key});
// ///
// ///   @override
// ///   State<MyWidget> createState() => _MyWidgetState();
// /// }
// ///
// /// class _MyWidgetState extends State<MyWidget>
// ///     with ScopeConsumer<MyFeatureScope, MyFeatureDeps, MyFeatureContent> {
// ///   @override
// ///   Widget build(BuildContext context) {
// ///     // Access scope content via `scope`
// ///     return Text(scope.someValue);
// ///   }
// /// }
// /// ```
// ///
// /// Or:
// ///
// /// ```dart
// /// typedef MyFeatureConsumer =
// ///     ScopeConsumer<MyFeatureScope, MyFeatureDeps, MyFeatureContent>;
// ///
// /// class MyWidget extends StatefulWidget {
// ///   const MyWidget({super.key});
// ///
// ///   @override
// ///   State<MyWidget> createState() => _MyWidgetState();
// /// }
// ///
// /// class _MyWidgetState extends State<MyWidget> with MyFeatureConsumer {
// ///   @override
// ///   Widget build(BuildContext context) {
// ///     // Access scope content via `scope`
// ///     return Text(scope.someValue);
// ///   }
// /// }
// /// ```
// mixin ScopeConsumer<S extends Scope<S, D, C>, D extends ScopeDeps,
//     C extends ScopeContent<S, D, C>> {
//   C? _scope;
//   C get scope => _scope ??= Scope.of<S, D, C>(context);

//   BuildContext get context;
// }
