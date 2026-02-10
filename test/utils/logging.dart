import 'dart:io';

import 'package:ansi_escape_codes/ansi_escape_codes.dart' as ansi;
import 'package:pkglog/pkglog.dart';
import 'package:scopo/scopo.dart';

void logInit() {
  ScopeConfig.isDebug = true;
  // ScopeConfig.logger.level = LogLevel.all;

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
          LogLevel.shout => const ansi.Color256(ansi.Colors.rgb300),
          _ => null,
        },
      ),
    );

    ScopeConfig.logger[level].print = printer.print;
  }
}
