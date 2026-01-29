import 'package:flutter/foundation.dart';

part 'scope_log.dart';

RawScopeLogCallback get d => ScopeConfig.log._log;
RawScopeLogCallback get i => ScopeConfig.logInfo._log;
RawScopeLogCallback get e => ScopeConfig.logError._log;

// ignore: avoid_classes_with_only_static_members
abstract final class ScopeConfig {
  static bool isDebug = false;
  static final log = ScopeLog();
  static final logInfo = ScopeLog();
  static final logError = ScopeLog();
}
