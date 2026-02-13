import 'package:meta/meta.dart';
import 'package:pkglog/pkglog.dart';

part 'scope_log.dart';

// ignore: avoid_classes_with_only_static_members
/// {@category debug}
abstract final class ScopeConfig {
  @visibleForTesting
  static final logger = Logger('scopo', level: LogLevel.info);

  // ignore: avoid_setters_without_getters
  static set logLevel(ScopeLogLevel level) {
    logger.level = level.toLoggerLevel();
  }

  static void disableLog() {
    logger.level = LogLevel.off;
  }

  // ignore: use_setters_to_change_properties
  static void setLogBuilder(String Function(ScopeLogMessage) builder) {
    logger.builder = (msg) => builder(ScopeLogMessage._(msg));
  }

  static void setLogBuilderFor(
    ScopeLogLevel level,
    String Function(ScopeLogMessage) builder,
  ) {
    logger[level.toLoggerLevel()].builder =
        (msg) => builder(ScopeLogMessage._(msg));
  }

  // ignore: use_setters_to_change_properties
  static void setLogPrinter(void Function(String) printer) {
    logger.printer = printer;
  }

  static void setLogPrinterFor(
    ScopeLogLevel level,
    void Function(String) printer,
  ) {
    logger[level.toLoggerLevel()].printer = printer;
  }

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
