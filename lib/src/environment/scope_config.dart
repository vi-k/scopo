import 'package:pkglog/pkglog.dart';

final Logger log = ScopeConfig.logger;

// ignore: avoid_classes_with_only_static_members
/// {@category debug}
abstract final class ScopeConfig {
  // ignore: avoid_setters_without_getters
  static set isDebug(bool value) {
    logger.level = value ? LogLevel.debug : LogLevel.info;
  }

  static final logger = Logger(
    'scopo',
    level: LogLevel.info,
  );

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
