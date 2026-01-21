import 'package:ansi_escape_codes/ansi_escape_codes.dart' as ansi;
import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'app/splash_screen.dart';
import 'home/home.dart';
import 'home/home_dependencies.dart';
// ignore: unused_import
import 'utils/app_environment.dart';

void main() {
  final defaultPrinter = ansi.AnsiPrinter(
    defaultState: const ansi.SgrPlainState(
      foreground: ansi.Color256(ansi.Colors.gray12),
    ),
  );

  ScopeConfig.log.isEnabled = true;
  ScopeConfig.log.log = (source, message, error, stackTrace) {
    defaultPrinter.print(
      ScopeLog.buildDefaultMessage(
        source,
        message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  };

  final errorPrinter = ansi.AnsiPrinter(
    defaultState: const ansi.SgrPlainState(
      foreground: ansi.Color256(ansi.Colors.rgb500),
    ),
  );

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

  // Fake errors block

  // App scope

  // AppEnvironment.errorOnFakeAnalyticsInit = true;
  // AppEnvironment.errorOnFakeAnalyticsDispose = true;

  // AppEnvironment.errorOnFakeAppHttpClientInit = true;
  // AppEnvironment.errorOnFakeAppHttpClientClose = true;

  // AppEnvironment.errorOnFakeServiceInit = true;
  // AppEnvironment.errorOnFakeServiceDispose = true;

  // Home scope

  // AppEnvironment.errorOnFakeUserHttpClientInit = true;
  // AppEnvironment.errorOnFakeUserHttpClientClose = true;

  // AppEnvironment.errorOnFakeBlocLoading = true;

  // AppEnvironment.errorOnFakeControllerInit = true;
  // AppEnvironment.errorOnFakeControllerDispose = true;

  runApp(
    App(
      init: AppDependencies.init,
      initBuilder: (context, progress) => SplashScreen(progress: progress),
      builder: (context) {
        return Home(init: HomeDependencies().init);
      },
    ),
  );
}
