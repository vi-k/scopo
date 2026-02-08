import 'dart:io';

import 'package:ansi_escape_codes/ansi_escape_codes.dart' as ansi;
import 'package:scopo/scopo.dart';

void logInit() {
  ScopeConfig.isDebug = true;

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
        foreground: ansi.Color256(ansi.Colors.rgb023),
      ),
    ),
  );
  ScopeConfig.logError.log = _logByPrinter(
    ansi.AnsiPrinter(
      ansiCodesEnabled: ansiCodesEnabled,
      defaultState: const ansi.SgrPlainState(
        foreground: ansi.Color256(ansi.Colors.rgb300),
      ),
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
