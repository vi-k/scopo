import 'dart:math';

import 'package:scopo/scopo.dart';
import 'package:scopo_demo/common/data/real_services/key_value_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/domain/fake_exception.dart';
import '../common/data/fake_services/analytics.dart';
import '../common/data/fake_services/connectivity.dart';
import '../common/data/fake_services/http_client.dart';
import '../common/data/fake_services/some_controller.dart';
import '../utils/app_environment.dart';
import 'app.dart';

/// Dependencies for [App] scope.
///
/// They are initialized asynchronously in the [init] stream.
class AppDeps implements ScopeDeps {
  final SharedPreferences _sharedPreferences;
  final HttpClient httpClient;
  final Connectivity connectivity;
  final Analytics analytics;
  final SomeController someController;

  AppDeps({
    required SharedPreferences sharedPreferences,
    required this.httpClient,
    required this.connectivity,
    required this.analytics,
    required this.someController,
  }) : _sharedPreferences = sharedPreferences;

  KeyValueService keyValueService(String prefix) => KeyValueService(
        sharedPreferences: _sharedPreferences,
        prefix: prefix,
      );

  /// Method uses [DoubleProgressIterator] to track and report granular
  /// initialization progress ([double] 0.0 to 1.0).
  ///
  /// It simulates random initialization errors using [AppEnvironment]
  /// probabilities.
  static Stream<ScopeInitState<double, AppDeps>> init() async* {
    SharedPreferences? sharedPreferences;
    HttpClient? httpClient;
    Connectivity? connectivity;
    Analytics? analytics;
    SomeController? someController;
    var isInitialized = false;

    final progressIterator = DoubleProgressIterator(count: 5);

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
      sharedPreferences = await SharedPreferences.getInstance();
      randomFakeError('$SharedPreferences initialization error');
      yield ScopeProgress(progressIterator.nextProgress());

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

      yield ScopeReady(
        AppDeps(
          sharedPreferences: sharedPreferences,
          httpClient: httpClient,
          connectivity: connectivity,
          analytics: analytics,
          someController: someController,
        ),
      );

      isInitialized = true;
    } finally {
      if (!isInitialized) {
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
