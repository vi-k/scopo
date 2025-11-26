part of 'scope.dart';

typedef ErrorWithStackTrace = ({Object error, StackTrace stackTrace});

typedef ScopeLogCallback = void Function(
  String? source,
  String? message,
  ErrorWithStackTrace? error,
);

typedef _ScopeLogCallback = void Function(
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

  set log(ScopeLogCallback value) {
    _userLog = value;
  }

  _ScopeLogCallback _log = _noLog;

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
          error == null
              ? null
              : (error: error, stackTrace: stackTrace ?? StackTrace.empty));

  static String buildDefaultMessage(
    String? source,
    String? message, [
    ErrorWithStackTrace? error,
  ]) {
    return '[scopo]'
        '${source == null ? '' : ' $source:'}'
        ' ${message ?? 'null'}'
        '${error == null ? '' : '\n${error.error}${error.stackTrace == StackTrace.empty ? '' : '\n${error.stackTrace}'}'}';
  }

  static void _defaultLog(
    String? source,
    String? message,
    ErrorWithStackTrace? error,
  ) {
    // ignore: avoid_print
    print(buildDefaultMessage(source, message, error));
  }
}
