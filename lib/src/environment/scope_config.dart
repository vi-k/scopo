import 'package:flutter/foundation.dart';

part 'scope_log.dart';

RawScopeLogCallback get d => ScopeConfig.log._log;
RawScopeLogCallback get e => ScopeConfig.logError._log;

abstract final class ScopeConfig {
  static final log = ScopeLog();
  static final logError = ScopeLog();
}
