part of 'scope.dart';

_ScopeLogCallback get _debug => ScopeConfig.debug._log;
_ScopeLogCallback get _debugError => ScopeConfig.debugError._log;

abstract final class ScopeConfig {
  static final debug = ScopeLog();
  static final debugError = ScopeLog();
}
