part of 'scope_config.dart';

typedef ScopeLogPublisher = CustomLogPublisher<ScopeLog>;
typedef ScopeLogFormatter<Out extends Object?>
    = CustomLogFormatter<ScopeLog, Out>;

final ScopeLogger log = ScopeConfig.logger;

abstract final class ScopeLogLevel {
  static const off = Levels.off;
  static const verbose = Levels.verbose;
  static const debug = Levels.debug;
  static const info = Levels.info;
  static const error = Levels.error;
  static const all = Levels.all;
}

typedef ScopeLogFn = bool Function(
  Object? message, {
  Object? error,
  StackTrace? stackTrace,
});

final class ScopeLog extends CustomLog {
  final DateTime timestamp;
  final LazyString _lazyPath;
  final LazyString _lazyMessage;

  ScopeLog(
    super.levelLogger, {
    super.error,
    super.stackTrace,
    required LazyString path,
    required Object? message,
  })  : timestamp = DateTime.now(),
        _lazyPath = path,
        _lazyMessage = LazyString(message);

  String get path => _lazyPath.value;
  String? get message => _lazyMessage.value;
}

final class ScopeLevelLogger extends CustomLevelLogger<ScopeLogger,
    ScopeLevelLogger, ScopeLogFn, ScopeLog> {
  ScopeLevelLogger({required super.level, required super.name, super.shortName})
      : super(
          noLog: (_, {error, stackTrace}) => true,
          publisher: const CustomLogFormatter(
            format: ScopeLogger.defaultFormat,
            output: print,
          ),
        );

  @override
  ScopeLogFn get processLog => (message, {error, stackTrace}) {
        publisher.publish(
          ScopeLog(
            this,
            path: logger._lazyPath,
            message: message,
            error: error,
            stackTrace: stackTrace,
          ),
        );

        return true;
      };
}

final class ScopeLogger
    extends CustomLogger<ScopeLogger, ScopeLevelLogger, ScopeLogFn, ScopeLog> {
  final LazyString _lazyPath;
  String pathSeparator = ' | ';

  ScopeLogger(Object name) : _lazyPath = LazyString(name);

  ScopeLogger._(super.parent, Object name)
      : _lazyPath = LazyString(
          () => '${parent.path}'
              '${parent.pathSeparator}'
              '${LazyString(name).value}',
        ),
        pathSeparator = parent.pathSeparator,
        super.sub();

  String get path => _lazyPath.value;

  ScopeLogger withAddedName(Object name) => ScopeLogger._(this, name);

  final ScopeLevelLogger _v = ScopeLevelLogger(
    level: Levels.verbose,
    name: 'verbose',
  );
  final ScopeLevelLogger _d = ScopeLevelLogger(
    level: Levels.debug,
    name: 'debug',
  );
  final ScopeLevelLogger _i = ScopeLevelLogger(
    level: Levels.info,
    name: 'info',
  );
  final ScopeLevelLogger _e = ScopeLevelLogger(
    level: Levels.error,
    name: 'error',
  );

  ScopeLogFn get v => _v.log;
  ScopeLogFn get d => _d.log;
  ScopeLogFn get i => _i.log;
  ScopeLogFn get e => _e.log;

  @override
  void registerLevels() {
    registerLevel(_v);
    registerLevel(_d);
    registerLevel(_i);
    registerLevel(_e);
  }

  static String defaultFormat(ScopeLog entry) => '[${entry.shortLevelName}]'
      ' ${entry.path}'
      ' | ${entry.message}'
      '${entry.error == null ? '' : ': ${entry.error}'}'
      '${entry.stackTrace == null || entry.stackTrace == StackTrace.empty //
          ? '' : '\n${entry.stackTrace}'}';
}
