import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:five_scenarios/cobalt_screen.dart';
import 'package:five_scenarios/depend_screen.dart';
import 'package:five_scenarios/domain.dart';
import 'package:five_scenarios/riverpod_screen.dart';
import 'package:five_scenarios/scopo_screen.dart';
import 'package:five_scenarios/watch_it_screen.dart';
import 'package:scopo/scopo.dart';

/// Real time interleaved with frames, so delays in the domain actually pass.
Future<void> settle(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 10) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

String screenText(WidgetTester tester) {
  final texts = tester.widgetList<Text>(find.byType(Text));
  return texts.map((t) => t.data).join(' | ');
}

typedef Host = Widget Function(Widget child);

late CobaltScope cobaltRoot;

Map<String, (Widget Function(), Host)> impls() => {
      'scopo': (ScopoAccountScreen.new, (c) => c),
      'cobalt': (
        CobaltAccountScreen.new,
        (c) => CobaltScopeProvider(scope: cobaltRoot, child: c),
      ),
      'riverpod': (
        RiverpodAccountScreen.new,
        (c) => ProviderScope(retry: (_, _) => null, child: c),
      ),
      'watch_it': (WatchItAccountScreen.new, (c) => c),
      'riverpod-naive': (
        NaiveRiverpodAccountScreen.new,
        (c) => ProviderScope(retry: (_, _) => null, child: c),
      ),
      'depend': (DependAccountScreen.new, (c) => c),
      'scopo-keyed': (
        () => const ScopoAccountScreen(scopeKey: 'account'),
        (c) => AsyncScopeCoordinator(child: c),
      ),
    };

Widget wrap(Host host, Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: host(child),
    );

void main() {
  setUp(() async {
    resetDomain();
    ScopeConfig.pauseAfterInitializationEnabled = false;
    cobaltRoot = CobaltScope.root(name: 'app');
    await cobaltRoot.init();
    await GetIt.I.reset();
  });

  for (final MapEntry(key: name, value: (make, host)) in impls().entries) {
    final screen = make();
    group(name, () {
      testWidgets('ready, then leave', (tester) async {
        await tester.pumpWidget(wrap(host, screen));
        await settle(tester, 400);
        final shown = screenText(tester);
        await tester.pumpWidget(wrap(host, const SizedBox()));
        await settle(tester, 400);
        // ignore: avoid_print
        print('[$name] ready-then-leave: shown="$shown"\n  ${log.join('\n  ')}');
      });

      testWidgets('leave while the database is opening', (tester) async {
        await tester.pumpWidget(wrap(host, screen));
        await settle(tester, 30);
        final shown = screenText(tester);
        await tester.pumpWidget(wrap(host, const SizedBox()));
        await settle(tester, 600);
        // ignore: avoid_print
        print('[$name] leave-during-open: shown="$shown"\n  ${log.join('\n  ')}');
      });

      testWidgets('parent rebuilds after ready', (tester) async {
        await tester.pumpWidget(wrap(host, make()));
        await settle(tester, 400);
        // A fresh widget instance in the same place: what a parent rebuild
        // (theme, locale, MediaQuery) does to a screen.
        await tester.pumpWidget(wrap(host, make()));
        await settle(tester, 400);
        final shown = screenText(tester);
        await tester.pumpWidget(wrap(host, const SizedBox()));
        await settle(tester, 400);
        // ignore: avoid_print
        print('[$name] rebuild: shown="$shown"\n  ${log.join('\n  ')}');
      });

      testWidgets('reopen at once', (tester) async {
        await tester.pumpWidget(
          wrap(host, KeyedSubtree(key: const ValueKey(1), child: make())),
        );
        await settle(tester, 400);
        log.add('--- reopen');
        await tester.pumpWidget(
          wrap(host, KeyedSubtree(key: const ValueKey(2), child: make())),
        );
        await settle(tester, 600);
        final shown = screenText(tester);
        await tester.pumpWidget(wrap(host, const SizedBox()));
        await settle(tester, 400);
        // ignore: avoid_print
        print('[$name] reopen: shown="$shown"\n  ${log.join('\n  ')}');
      });

      testWidgets('session restore fails', (tester) async {
        sessionFails = true;
        await tester.pumpWidget(wrap(host, screen));
        await settle(tester, 500);
        final shown = screenText(tester);
        await tester.pumpWidget(wrap(host, const SizedBox()));
        await settle(tester, 300);
        // ignore: avoid_print
        print('[$name] restore-fails: shown="$shown"\n  ${log.join('\n  ')}');
      });
    });
  }
}
