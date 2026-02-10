import 'dart:io';

import 'package:ansi_escape_codes/ansi_escape_codes.dart' as ansi;
import 'package:flutter/material.dart';
import 'package:pkglog/pkglog.dart';
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
  // ScopeConfig.logger.level = LogLevel.all;

  //
  // Logging
  //

  for (final level in LogLevel.values) {
    final printer = ansi.AnsiPrinter(
      ansiCodesEnabled: !Platform.isIOS,
      defaultState: ansi.SgrPlainState(
        foreground: switch (level) {
          LogLevel.verbose => const ansi.Color256(ansi.Colors.gray8),
          LogLevel.debug => const ansi.Color256(ansi.Colors.gray12),
          LogLevel.info => const ansi.Color256(ansi.Colors.rgb345),
          LogLevel.warning => const ansi.Color256(ansi.Colors.rgb440),
          LogLevel.error => const ansi.Color256(ansi.Colors.rgb400),
          LogLevel.shout => const ansi.Color256(ansi.Colors.rgb550),
        },
        background: switch (level) {
          LogLevel.verbose => null,
          LogLevel.debug => null,
          LogLevel.info => null,
          LogLevel.warning => null,
          LogLevel.error => null,
          LogLevel.shout => const ansi.Color256(ansi.Colors.rgb300),
        },
      ),
    );

    ScopeConfig.logger[level].print = printer.print;
  }

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
