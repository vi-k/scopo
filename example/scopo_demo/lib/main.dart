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
  //
  // Logging
  //

  ScopeConfig.logger.level = ScopeLogLevel.info;

  void setLogPrinter(
    int level,
    ansi.Color foreground, {
    ansi.Color? background,
  }) {
    final printer = ansi.AnsiPrinter(
      ansiCodesEnabled: !Platform.isIOS,
      defaultState: ansi.SgrPlainState(
        foreground: foreground,
        background: background,
      ),
    );

    ScopeConfig.logger[level].printer = printer.print;
  }

  setLogPrinter(ScopeLogLevel.verbose, const ansi.Color256(ansi.Colors.gray7));
  setLogPrinter(ScopeLogLevel.debug, const ansi.Color256(ansi.Colors.gray12));
  setLogPrinter(ScopeLogLevel.info, const ansi.Color256(ansi.Colors.rgb345));
  setLogPrinter(ScopeLogLevel.error, const ansi.Color256(ansi.Colors.rgb400));

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
