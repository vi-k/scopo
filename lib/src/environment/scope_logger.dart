part of 'scope_config.dart';

final ScopeLogger log = ScopeConfig.logger;

final class LazyNonNullableString extends TypedLazy<String> {
  final String fallbackValue;

  LazyNonNullableString(super.unresolved, this.fallbackValue);

  @override
  String convert(Object? resolved) => resolved?.toString() ?? fallbackValue;
}

abstract final class ScopeLogLevel {
  static const off = Levels.off;
  static const verbose = Levels.verbose;
  static const debug = Levels.debug;
  static const info = Levels.info;
  static const error = Levels.error;
  static const all = Levels.all;
}

typedef ScopeLogFunction = bool Function(
  Object? message, {
  Object? error,
  StackTrace? stackTrace,
});

final class ScopeLogEntry extends CustomLogEntry {
  final DateTime timestamp;
  final List<String> path;
  final LazyString _lazyMessage;

  ScopeLogEntry(
    super.levelLogger, {
    super.error,
    super.stackTrace,
    required this.path,
    required Object? message,
  })  : timestamp = DateTime.now(),
        _lazyMessage = LazyString(message);

  String? get message => _lazyMessage.value;
}

final class ScopeLevelLogger extends CustomLevelLogger<ScopeLogger,
    ScopeLevelLogger, ScopeLogFunction, ScopeLogEntry, String> {
  ScopeLevelLogger({required super.level, required super.name, super.shortName})
      : super(
          noLog: (_, {error, stackTrace}) => true,
          builder: ScopeLogger.defaultBuilder,
          printer: print,
        );

  @override
  ScopeLogFunction get processLog => (message, {error, stackTrace}) {
        final entry = ScopeLogEntry(
          this,
          error: error,
          stackTrace: stackTrace,
          path: logger.path,
          message: message,
        );

        printer(builder(entry));

        return true;
      };
}

final class ScopeLogger extends CustomLogger<ScopeLogger, ScopeLevelLogger,
    ScopeLogFunction, ScopeLogEntry, String> {
  final LazyNonNullableString _lazyName;
  String get name => _lazyName.value;

  ScopeLogger? _parent;

  late final List<String> path = _buildPath();

  ScopeLogger(Object name)
      : _parent = null,
        _lazyName = LazyNonNullableString(name, 'root');

  ScopeLogger._(super.parent, Object name)
      : _parent = parent,
        _lazyName = LazyNonNullableString(name, 'unknown'),
        super.sub();

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

  ScopeLogFunction get v => _v.log;
  ScopeLogFunction get d => _d.log;
  ScopeLogFunction get i => _i.log;
  ScopeLogFunction get e => _e.log;

  @override
  void registerLevels() {
    registerLevel(_v);
    registerLevel(_d);
    registerLevel(_i);
    registerLevel(_e);
  }

  static String defaultBuilder(ScopeLogEntry entry) =>
      '[${entry.shortLevelName}]'
      ' ${entry.path.join(' | ')}'
      ' | ${entry.message}'
      '${entry.error == null ? '' : ': ${entry.error}'}'
      '${entry.stackTrace == null || entry.stackTrace == StackTrace.empty //
          ? '' : '\n${entry.stackTrace}'}';

  List<String> _buildPath() {
    switch (_parent) {
      case null:
        return UnmodifiableListView(List.filled(1, name));

      case final parent:
        _parent = null;
        return UnmodifiableListView(
          List.generate(growable: false, parent.path.length + 1, (index) {
            if (index == parent.path.length) return name;
            return parent.path[index];
          }),
        );
    }
  }
}
