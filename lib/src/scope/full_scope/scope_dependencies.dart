part of '../scope.dart';

/// A container for dependencies (e.g., repositories, services).
///
/// {@category Scope}
// ignore: one_member_abstracts
abstract interface class ScopeDependencies {
  /// Lets go of whatever cannot wait for [dispose].
  ///
  /// Cancel subscriptions and detach listeners here. It runs exactly once,
  /// always before [dispose], whether the scope was removed from the tree or
  /// closed with `close()`.
  void onUnmount();

  /// Disposes of the dependencies, releasing any resources they hold.
  FutureOr<void> dispose();
}
