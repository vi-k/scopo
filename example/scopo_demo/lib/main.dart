import 'dart:io';

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
  ScopeConfig.isDebug = true;

  //
  // Logging
  //

  final ansiCodesEnabled = !Platform.isIOS;

  ScopeConfig.log.log = _logByPrinter(
    ansi.AnsiPrinter(
      ansiCodesEnabled: ansiCodesEnabled,
      defaultState: const ansi.SgrPlainState(
        foreground: ansi.Color256(ansi.Colors.gray8),
      ),
    ),
  );
  ScopeConfig.logInfo.log = _logByPrinter(
    ansi.AnsiPrinter(
      ansiCodesEnabled: ansiCodesEnabled,
      defaultState: const ansi.SgrPlainState(
        foreground: ansi.Color256(ansi.Colors.gray16),
      ),
    ),
  );
  ScopeConfig.logError.log = _logByPrinter(
    ansi.AnsiPrinter(
      ansiCodesEnabled: ansiCodesEnabled,
      defaultState: const ansi.SgrPlainState(
        foreground: ansi.Color256(ansi.Colors.rgb500),
      ),
    ),
  );

  //
  // Scope timeouts
  //

  // ScopeConfig.defaultScopeKeysTimeout = const Duration(milliseconds: 500);
  // ScopeConfig.defaultWaitForChildrenTimeout = const Duration(milliseconds: 500);

  //
  // Fake errors block
  //

  // `App` scope

  // AppEnvironment.errorOnFakeAnalyticsInit = true;
  // AppEnvironment.errorOnFakeAnalyticsDispose = true;

  // AppEnvironment.errorOnFakeAppHttpClientInit = true;
  // AppEnvironment.errorOnFakeAppHttpClientClose = true;

  // AppEnvironment.errorOnFakeServiceInit = true;
  // AppEnvironment.errorOnFakeServiceDispose = true;

  // `Home` scope

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

void Function(String?, String?, Object?, StackTrace?) _logByPrinter(
  ansi.AnsiPrinter printer,
) =>
    (source, message, error, stackTrace) {
      printer.print(
        ScopeLog.buildDefaultMessage(
          source,
          message,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    };
