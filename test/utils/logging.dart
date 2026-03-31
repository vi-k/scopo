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
    final printer = ansi.Printer(
      ansiCodesEnabled: !Platform.isIOS,
      defaultStyle: ansi.Style(
        foreground: foreground,
        background: background,
      ),
    );

    ScopeConfig.logger[level].publisher = ScopeLogFormatter(
      format: ScopeLogger.defaultFormat,
      output: printer.print,
    );
  }

  setPrinter(ScopeLogLevel.verbose, ansi.Color256.gray7);
  setPrinter(ScopeLogLevel.debug, ansi.Color256.gray12);
  setPrinter(ScopeLogLevel.info, ansi.Color256.rgb345);
  setPrinter(ScopeLogLevel.error, ansi.Color256.rgb400);
}
