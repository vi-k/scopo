part of '../scope.dart';

/// {@category AsyncScope}
final asyncScopeRoot = AsyncScopeRoot._();

/// {@category AsyncScope}
final class AsyncScopeRoot with Diagnosticable, AsyncScopeParent {
  AsyncScopeRoot._();

  @override
  String toStringShort() => '$AsyncScopeRoot';
}
