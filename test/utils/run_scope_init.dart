import 'package:scopo/scopo.dart';

/// Gives a hand-driven initialization the same job lifetime as a scope's.
Future<T> runScopeInit<T>(Future<T> Function(ScopeInitContext ctx) body) =>
    (ScopeInitJob<T>(body)..start()).value;
