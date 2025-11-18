import 'package:ansi_escape_codes/ansi_escape_codes.dart' as ansi;
import 'package:flutter/material.dart';
import 'package:flutter_scope/flutter_scope.dart';
import 'package:scope_example/app/splash_screen.dart';
import 'package:scope_example/utils/app_environment.dart';

import 'app/app.dart';
import 'app/app_deps.dart';
import 'home/home.dart';
import 'home/home_deps.dart';

void main() {
  final errorPrinter = ansi.AnsiPrinter(
    defaultState: ansi.SgrPlainState(
      foreground: ansi.Color256(ansi.Colors.rgb500),
    ),
  );

  ScopeConfig.debug.isEnabled = true;
  ScopeConfig.debugError.isEnabled = true;
  ScopeConfig.debugError.log = (
    source,
    message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    errorPrinter.print(
      '[flutter_scope]'
      '${source == null ? '' : ' $source:'}'
      ' ${message ?? 'null'}'
      '${error == null ? '' : '\n$error'}'
      '${stackTrace == null ? '' : '\n$stackTrace'}',
    );
  };

  // AppEnvironment.probabilityOfAppRandomError = 0.3;
  AppEnvironment.probabilityOfAppRandomError = 0.0;
  // AppEnvironment.probabilityOfHomeRandomError = 0.3;
  AppEnvironment.probabilityOfHomeRandomError = 0.0;

  // AppEnvironment.enabledConnectionDuration = (5, 10);
  // AppEnvironment.disabledConnectionDuration = (5, 10);

  runApp(
    App(
      init: AppDeps.init,
      onInit: (progress) => SplashScreen(progress: progress),
      builder: (_) => Home(init: HomeDeps.init),
    ),
  );
}
