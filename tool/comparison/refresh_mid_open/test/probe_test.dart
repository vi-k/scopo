// Runs the four probes under the same script: show the screen, tap refresh
// while the database is still opening, let everything settle, remove the
// screen, let everything settle again. The `events` log says what each
// package did with the two owners of the database.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refresh_mid_open/common.dart';
import 'package:refresh_mid_open/probe_get_it.dart';
import 'package:refresh_mid_open/probe_riverpod.dart';
import 'package:refresh_mid_open/probe_scopo.dart';
import 'package:refresh_mid_open/probe_yx_scope.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> script(String name, WidgetTester tester, Widget app) async {
  events.clear();
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString().split('\n').first);
  };
  try {
    await tester.pumpWidget(app);
    await tester.pump(const Duration(milliseconds: 150));
    events.add('-- refresh while db is opening --');
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    await settle(tester);
    events.add('-- screen removed --');
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  } finally {
    FlutterError.onError = previous;
  }
  debugPrint('=== $name ===');
  for (final e in events) {
    debugPrint('  $e');
  }
  for (final e in errors) {
    debugPrint('  FlutterError: $e');
  }
}

void main() {
  testWidgets('scopo', (tester) async {
    await script('scopo', tester, const ScopoProbeApp());
  });

  testWidgets('riverpod', (tester) async {
    await script('riverpod', tester, const RiverpodProbeApp());
  });

  testWidgets('get_it + watch_it', (tester) async {
    await script('get_it + watch_it', tester, const GetItProbeApp());
  });

  testWidgets('yx_scope', (tester) async {
    await script('yx_scope', tester, const YxProbeApp());
  });
}
