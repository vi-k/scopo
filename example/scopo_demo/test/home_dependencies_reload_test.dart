import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:scopo/scopo.dart';
import 'package:scopo_demo/app/app.dart';
import 'package:scopo_demo/app/app_dependencies.dart';
import 'package:scopo_demo/app/app_error.dart';
import 'package:scopo_demo/common/data/fake_services/fake_bloc.dart';
import 'package:scopo_demo/home/home.dart';
import 'package:scopo_demo/home/home_dependencies.dart';
import 'package:scopo_demo/utils/app_environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _advance(WidgetTester tester, int rounds) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Advances until [done], at most [rounds] times.
Future<void> _advanceUntil(
  WidgetTester tester,
  bool Function() done, {
  int rounds = 200,
}) async {
  for (var i = 0; i < rounds && !done(); i++) {
    await _advance(tester, 1);
  }
}

void main() {
  setUp(() {
    final previousPause = ScopeConfig.pauseAfterInitializationEnabled;
    final previousInit = AppEnvironment.defaultInitPause;
    final previousDispose = AppEnvironment.defaultDisposePause;
    final previousError = AppEnvironment.errorOnFakeBlocLoading;
    final previousChildren = ScopeConfig.defaultWaitForChildrenTimeout;
    ScopeConfig.pauseAfterInitializationEnabled = false;
    // The scopes on the open tab take seconds to let go, which is longer
    // than the default wait of the scopes above them. The app never removes
    // `Home` while it runs; these tests do.
    ScopeConfig.defaultWaitForChildrenTimeout = const Duration(seconds: 10);
    AppEnvironment.defaultInitPause = Duration.zero;
    AppEnvironment.defaultDisposePause = Duration.zero;
    AppEnvironment.errorOnFakeBlocLoading = false;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    addTearDown(() {
      ScopeConfig.pauseAfterInitializationEnabled = previousPause;
      AppEnvironment.defaultInitPause = previousInit;
      AppEnvironment.defaultDisposePause = previousDispose;
      AppEnvironment.errorOnFakeBlocLoading = previousError;
      ScopeConfig.defaultWaitForChildrenTimeout = previousChildren;
    });
  });

  testWidgets(
    'ready Home accepts another bloc load without reinitializing',
    // The open tab shows the demo's console, a global that lives as long as
    // the app and is never disposed of.
    experimentalLeakTesting: LeakTesting.settings.withIgnored(
      classes: ['Console'],
    ),
    (tester) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await _advance(tester, 30);
      });
      final dependencies = HomeDependencies();
      var initializations = 0;
      var completions = 0;
      await tester.pumpWidget(
        App(
          init: AppDependencies.init,
          progressBuilder: (_, progress) => Text(progress ?? ''),
          builder: (_) => Home(
            init: (_, ctx) async {
              initializations++;
              final result = await dependencies.init(null, ctx);
              completions++;
              return result;
            },
          ),
        ),
      );
      await _advance(tester, 20);

      final context = tester.element(find.byType(TabBarView));
      final home = Home.of(context);
      final bloc = home.dependencies.bloc;
      final firstState = bloc.state;
      expect(firstState, isA<FakeBlocSuccess>());
      expect(initializations, 1);
      expect(completions, 1);

      bloc.add(FakeBlocLoad());
      await _advance(tester, 5);

      expect(bloc.state, isA<FakeBlocSuccess>());
      expect(bloc.state, isNot(same(firstState)));
      expect(Home.of(context), same(home));
      expect(initializations, 1);
      expect(completions, 1);
      expect(tester.takeException(), isNull);

      // Home lets go of the bloc only after the scopes on the open tab have
      // finished their own disposal.
      await tester.pumpWidget(const SizedBox.shrink());
      await _advanceUntil(tester, () => bloc.isClosed);
      expect(bloc.isClosed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a first bloc load error still fails Home initialization', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await _advance(tester, 30);
    });
    AppEnvironment.errorOnFakeBlocLoading = true;
    final dependencies = HomeDependencies();
    Object? initializationError;
    var completions = 0;
    await tester.pumpWidget(
      App(
        init: AppDependencies.init,
        progressBuilder: (_, progress) => Text(progress ?? ''),
        builder: (_) => Home(
          init: (_, ctx) async {
            final result = await dependencies.init(null, ctx).onError<Object>((
              error,
              stackTrace,
            ) {
              initializationError = error;
              Error.throwWithStackTrace(error, stackTrace);
            });
            completions++;
            return result;
          },
        ),
      ),
    );
    await _advance(tester, 50);

    final errorScreen = tester.widget<AppError>(find.byType(AppError));
    expect(initializationError, isA<ScopeDependencyException>());
    final failure = initializationError! as ScopeDependencyException;
    expect(failure.name, 'bloc');
    expect(failure.error.toString(), contains('FakeBloc loading error'));
    expect(errorScreen.error, same(initializationError));
    expect(completions, 0);
    expect(find.byType(TabBarView), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await _advance(tester, 30);
    expect(dependencies.bloc.isClosed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
