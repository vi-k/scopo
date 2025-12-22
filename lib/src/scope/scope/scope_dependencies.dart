part of '../scope.dart';

/// A container for dependencies (e.g., repositories, services).
// ignore: one_member_abstracts
abstract interface class ScopeDependencies {
  FutureOr<void> dispose();
}
