part of '../../../scope.dart';

final class ScopeDependencyException implements Exception {
  final String name;
  final Object error;
  final StackTrace stackTrace;

  const ScopeDependencyException(this.name, this.error, this.stackTrace);

  @override
  String toString() => '$name: $error';
}
