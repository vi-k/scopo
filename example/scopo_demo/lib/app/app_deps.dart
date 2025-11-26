import 'dart:math';

import 'package:scopo/scopo.dart';

import '../common/fake_exception.dart';
import '../fake_dependencies/analytics.dart';
import '../fake_dependencies/connectivity.dart';
import '../fake_dependencies/http_client.dart';
import '../fake_dependencies/some_controller.dart';
import '../utils/app_environment.dart';
import 'app.dart';

/// Dependencies for [App] scope.
///
/// They are initialized asynchronously in the [init] stream.
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

  /// Method uses [DoubleProgressIterator] to track and report granular
  /// initialization progress ([double] 0.0 to 1.0).
  ///
  /// It simulates random initialization errors using [AppEnvironment]
  /// probabilities.
  static Stream<ScopeInitState<double, AppDeps>> init(
    ScopeHelper helper,
  ) async* {
    HttpClient? httpClient;
    Connectivity? connectivity;
    Analytics? analytics;
    SomeController? someController;

    final progressIterator = DoubleProgressIterator(count: 4);

    // Fake error block
    final random = Random();
    final throwFakeError =
        random.nextDouble() < AppEnvironment.probabilityOfAppRandomError;
    final depWithFakeError = random.nextInt(progressIterator.count);
    // ignore: avoid_print
    print(
      '[$AppDeps] '
      '${throwFakeError ? 'throw fake error on dep #${depWithFakeError + 1}' : 'no throw fake error'}',
    );
    void randomFakeError(String text) {
      if (throwFakeError && depWithFakeError == progressIterator.currentStep) {
        throw FakeException(text);
      }
    }

    try {
      httpClient = HttpClient();
      await httpClient.init();
      randomFakeError('$HttpClient initialization error');
      yield ScopeProgress(progressIterator.nextProgress());

      connectivity = Connectivity();
      await connectivity.init();
      randomFakeError('$Connectivity initialization error');
      yield ScopeProgress(progressIterator.nextProgress());

      analytics = Analytics();
      await analytics.init();
      randomFakeError('$Analytics initialization error');
      yield ScopeProgress(progressIterator.nextProgress());

      someController = SomeController();
      await someController.init();
      randomFakeError('$SomeController initialization error');
      yield ScopeProgress(progressIterator.nextProgress());

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
    } finally {
      if (helper.initializationNotCompleted) {
        await [
          httpClient?.dispose(),
          connectivity?.dispose(),
          analytics?.dispose(),
          someController?.dispose(),
        ].nonNulls.wait;
      }
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
