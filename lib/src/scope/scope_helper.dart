part of 'scope.dart';

/// A helper class used during the initialization phase to provide the
/// initialization function for the necessary data.
final class ScopeHelper {
  var _initializationNotCompleted = true;

  ScopeHelper();

  /// A flag that the `init` method can check at the end to see whether the
  /// scope has received the created dependencies or whether they need to be
  /// disposed of.
  ///
  /// Example:
  ///
  /// ```dart
  /// static Stream<ScopeInitState<String, MyDeps>> init(
  ///   ScopeHelper helper,
  /// ) async* {
  ///   SomeController? someController;
  ///   SomeResource? someResource;
  ///
  ///   try {
  ///     yield ScopeProgress('create $SomeController');
  ///     someController = SomeController();
  ///     await someController.init();
  ///
  ///     yield ScopeProgress('create $SomeResource');
  ///     someResource = await SomeResource.getInstance();
  ///
  ///     yield ScopeReady(
  ///       MyDeps(
  ///         someController: someController,
  ///         someResource: someResource,
  ///       ),
  ///     );
  ///   } finally {
  ///     if (helper.initializationNotCompleted) {
  ///       await [
  ///         someController?.dispose(),
  ///         someResource?.dispose(),
  ///       ].nonNulls.wait;
  ///     }
  ///   }
  /// }
  /// ```
  bool get initializationNotCompleted => _initializationNotCompleted;
}
