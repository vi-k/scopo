import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../common/fake_exception.dart';
import '../fake_dependencies/analytics.dart';
import '../fake_dependencies/connectivity.dart';
import '../fake_dependencies/http_client.dart';
import '../fake_dependencies/some_controller.dart';
import '../utils/app_environment.dart';

class AppDeps implements ScopeDeps {
  final HttpClient httpClient;
  final Connectivity connectivity;
  final Analytics analytics;
  final SomeController someController;

  AppDeps({
    required this.httpClient,
    required this.connectivity,
    required this.analytics,
    required this.someController,
  });

  static Stream<ScopeInitState<double, AppDeps>> init(
    BuildContext context,
  ) async* {
    HttpClient? httpClient;
    Connectivity? connectivity;
    Analytics? analytics;
    SomeController? someController;

    const depsCount = 4;
    var currentDepNum = 0;
    ScopeProgress<double, AppDeps> nextProgressStep() {
      final progress = ++currentDepNum / depsCount;
      assert(
        progress <= 1.0,
        'currentDepNum ($currentDepNum) > depsCount ($depsCount)',
      );
      return ScopeProgress(progress);
    }

    // Fake error block
    final random = Random();
    final throwFakeError =
        random.nextDouble() < AppEnvironment.probabilityOfAppRandomError;
    final depWithFakeError = random.nextInt(depsCount);
    // ignore: avoid_print
    print(
      '[$AppDeps] '
      '${throwFakeError ? 'throw fake error on dep #${depWithFakeError + 1}' : 'no throw fake error'}',
    );
    void randomFakeError(String text) {
      if (throwFakeError && depWithFakeError == currentDepNum) {
        throw FakeException(text);
      }
    }

    try {
      httpClient = HttpClient();
      await httpClient.init();
      randomFakeError('$HttpClient initialization error');
      yield nextProgressStep();

      connectivity = Connectivity();
      await connectivity.init();
      randomFakeError('$Connectivity initialization error');
      yield nextProgressStep();

      analytics = Analytics();
      await analytics.init();
      randomFakeError('$Analytics initialization error');
      yield nextProgressStep();

      someController = SomeController();
      await someController.init();
      randomFakeError('$SomeController initialization error');
      yield nextProgressStep();

      // Даём пользователю увидеть 100%.
      await Future<void>.delayed(const Duration(milliseconds: 500));

      yield ScopeReady(
        AppDeps(
          httpClient: httpClient,
          connectivity: connectivity,
          analytics: analytics,
          someController: someController,
        ),
      );
    } on Object {
      await [
        httpClient?.dispose(),
        connectivity?.dispose(),
        analytics?.dispose(),
        someController?.dispose(),
      ].nonNulls.wait;

      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await [
      httpClient.dispose(),
      connectivity.dispose(),
      analytics.dispose(),
      someController.dispose(),
    ].wait;
  }
}
