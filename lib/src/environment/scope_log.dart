part of 'scope_config.dart';

/// {@category debug}
typedef ScopeLogCallback = void Function(
  String? source,
  String? message,
  Object? error,
  StackTrace? stackTrace,
);

typedef RawScopeLogCallback = void Function(
  Object? source,
  Object? message, {
  Object? error,
  StackTrace? stackTrace,
});

/// {@category debug}
final class ScopeLog {
  bool? _isEnabled;
  bool get isEnabled => _isEnabled ?? ScopeConfig.isDebug;
  set isEnabled(bool value) {
    _isEnabled = value;
    _log = value ? _prepareLog : _noLog;
  }

  // ignore: avoid_setters_without_getters
  set log(ScopeLogCallback value) {
    _userLog = value;
  }

  late RawScopeLogCallback _log = isEnabled ? _prepareLog : _noLog;

  ScopeLogCallback _userLog = _defaultLog;

  static String? objToString(Object? obj) =>
      obj == null ? null : '${obj is Object? Function() ? obj() : obj}';

  static void _noLog(
    Object? source,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  void _prepareLog(
    Object? source,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _userLog(
        objToString(source),
        objToString(message),
        error,
        stackTrace,
      );

  static void _defaultLog(
    String? source,
    String? message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    // ignore: avoid_print
    print(
      buildDefaultMessage(
        source,
        message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  static String buildDefaultMessage(
    String? source,
    String? message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      '${source == null ? '' : '$source:'}'
      ' ${message ?? 'null'}'
      '${error == null ? '' : ': $error'}'
      '${stackTrace == null ? '' : '\n${stackTrace == StackTrace.empty ? 'no stack trace' : '$stackTrace'}'}';
}
