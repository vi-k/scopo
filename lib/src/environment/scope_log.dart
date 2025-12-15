part of 'scope_config.dart';

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

final class ScopeLog {
  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;
  set isEnabled(bool value) {
    _isEnabled = value;
    _log = value ? _prepareLog : _noLog;
  }

  // ignore: avoid_setters_without_getters
  set log(ScopeLogCallback value) {
    _userLog = value;
  }

  RawScopeLogCallback _log = _noLog;

  ScopeLogCallback _userLog = _defaultLog;

  static String? _objToStr(Object? obj) =>
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
        _objToStr(source),
        _objToStr(message),
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
      '[scopo]'
      '${source == null ? '' : ' $source:'}'
      ' ${message ?? 'null'}'
      '${error == null ? '' : ': $error'}'
      '${stackTrace == null ? '' : ':${stackTrace == StackTrace.empty ? ' no stack trace' : '\n$stackTrace'}'}';
}

String source(Diagnosticable diagnosticable, String method) =>
    '${diagnosticable.toStringShort()}.$method';
