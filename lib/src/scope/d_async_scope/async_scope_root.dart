part of '../scope.dart';

final asyncScopeRoot = AsyncScopeRoot._();

final class AsyncScopeRoot with Diagnosticable, AsyncScopeParent {
  AsyncScopeRoot._();

  @override
  String toStringShort() => '$AsyncScopeRoot';
}
