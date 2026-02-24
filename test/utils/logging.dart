import 'dart:io';

import 'package:ansi_escape_codes/ansi_escape_codes.dart' as ansi;
import 'package:scopo/scopo.dart';

void logInit() {
  ScopeConfig.logger.level = ScopeLogLevel.debug;

  void setPrinter(
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

  setPrinter(ScopeLogLevel.verbose, const ansi.Color256(ansi.Colors.gray7));
  setPrinter(ScopeLogLevel.debug, const ansi.Color256(ansi.Colors.gray12));
  setPrinter(ScopeLogLevel.info, const ansi.Color256(ansi.Colors.rgb345));
  setPrinter(ScopeLogLevel.error, const ansi.Color256(ansi.Colors.rgb400));
}
