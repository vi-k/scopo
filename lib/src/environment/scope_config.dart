import 'package:flutter/foundation.dart';

part 'scope_log.dart';

RawScopeLogCallback get d => ScopeConfig.log._log;
RawScopeLogCallback get i => ScopeConfig.logInfo._log;
RawScopeLogCallback get e => ScopeConfig.logError._log;

// ignore: avoid_classes_with_only_static_members
abstract final class ScopeConfig {
  static bool isDebug = false;

  /// Debug logging.
  static final log = ScopeLog();

  /// Info logging.
  static final logInfo = ScopeLog();

  /// Error logging.
  static final logError = ScopeLog();

  /// Forces pause to be disabled during testing and debugging.
  static bool pauseAfterInitializationEnabled = true;

  /// Timeout for waiting for `scopeKeys` to be released.
  ///
  /// If `null`, then there is no timeout.
  ///
  /// If zero, then the timeout is disabled.
  static Duration? defaultScopeKeysTimeout = const Duration(seconds: 3);

  /// Timeout for waiting for scopes to be disposed of.
  ///
  /// If `null`, then there is no timeout.
  ///
  /// If zero, then the timeout is disabled.
  static Duration? defaultWaitForChildrenTimeout = const Duration(seconds: 3);
}
