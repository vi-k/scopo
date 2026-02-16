part of 'scope_config.dart';

final Logger log = ScopeConfig.logger;

enum ScopeLogLevel {
  verbose,
  debug,
  info,
  warning,
  error;

  static const ScopeLogLevel all = verbose;

  LoggerLevel toLoggerLevel() => switch (this) {
        ScopeLogLevel.verbose => LogLevel.verbose,
        ScopeLogLevel.debug => LogLevel.debug,
        ScopeLogLevel.info => LogLevel.info,
        ScopeLogLevel.warning => LogLevel.warning,
        ScopeLogLevel.error => LogLevel.error,
      };

  static ScopeLogLevel fromLoggerLevel(LoggerLevel level) => switch (level) {
        LogLevel.verbose => ScopeLogLevel.verbose,
        LogLevel.debug => ScopeLogLevel.debug,
        LogLevel.info => ScopeLogLevel.info,
        LogLevel.warning => ScopeLogLevel.warning,
        LogLevel.error => ScopeLogLevel.error,
        LogLevel.critical => ScopeLogLevel.error,
      };
}

final class ScopeLogMessage with LogMessageWrapper<ScopeLogLevel> {
  @override
  final LogMessage msg;

  ScopeLogMessage._(this.msg);

  @override
  ScopeLogLevel get level => ScopeLogLevel.fromLoggerLevel(msg.level);

  static String defaultBuilder(ScopeLogMessage msg) => msg.toString();
}
