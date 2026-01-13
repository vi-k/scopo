import 'package:ansi_escape_codes/ansi_escape_codes.dart' as ansi;
import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import 'app/app.dart';
import 'app/app_deps.dart';
import 'app/splash_screen.dart';
import 'home/home.dart';
import 'home/home_dependencies.dart';

void main() {
  final errorPrinter = ansi.AnsiPrinter(
    defaultState: const ansi.SgrPlainState(
      foreground: ansi.Color256(ansi.Colors.rgb500),
    ),
  );

  ScopeConfig.log.isEnabled = true;
  ScopeConfig.logError.isEnabled = true;
  ScopeConfig.logError.log = (source, message, error, stackTrace) {
    errorPrinter.print(
      ScopeLog.buildDefaultMessage(
        source,
        message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  };

  // AppEnvironment.probabilityOfAppRandomError = 1.0;
  // AppEnvironment.probabilityOfHomeRandomError = 1.0;
  // AppEnvironment.enabledConnectionDuration = (5, 10);
  // AppEnvironment.disabledConnectionDuration = (5, 10);

  runApp(
    App(
      init: AppDependencies.init,
      initBuilder: (context, progress) => SplashScreen(progress: progress),
      builder: (context) {
        return const Home(init: HomeDependencies.init);
      },
    ),
  );
}
