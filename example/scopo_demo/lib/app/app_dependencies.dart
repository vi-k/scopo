import 'package:scopo/scopo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/data/fake_services/fake_analytics.dart';
import '../common/data/fake_services/fake_app_http_client.dart';
import '../common/data/fake_services/fake_service.dart';
import '../common/data/real_services/key_value_service.dart';
import '../utils/app_environment.dart';
import 'app.dart';

/// Dependencies for [App] scope.
///
/// They are initialized asynchronously in the [init] stream.
class AppDependencies implements ScopeDependencies {
  final SharedPreferences _sharedPreferences;
  final FakeAnalytics analytics;
  final FakeAppHttpClient httpClient;
  final FakeService service;

  AppDependencies({
    required SharedPreferences sharedPreferences,
    required this.httpClient,
    required this.service,
    required this.analytics,
  }) : _sharedPreferences = sharedPreferences;

  KeyValueService keyValueService(String prefix) =>
      KeyValueService(sharedPreferences: _sharedPreferences, prefix: prefix);

  /// Method uses [DoubleProgressIterator] to track and report granular
  /// initialization progress ([double] 0.0 to 1.0).
  ///
  /// It simulates random initialization errors using [AppEnvironment]
  /// probabilities.
  static Stream<ScopeInitState<double, AppDependencies>> init() async* {
    SharedPreferences? sharedPreferences;
    FakeAppHttpClient? httpClient;
    FakeService? service;
    FakeAnalytics? analytics;

    // В случае, если инициализация не завершилась, необходимо утилизировать
    // уже проинициализированные зависимости. Нам недостаточно обернуть код
    // в try/catch, т.к. процесс может не только завершиться ошибкой, но и быть
    // отменён извне. А это мы можем поймать только в try/finally. А был ли он
    // отменён или завершился успешно узнаем с помощью данного флага.
    var isInitialized = false;

    // Остлеживает прогресс инициализации.
    final progressIterator = DoubleProgressIterator(count: 4);

    try {
      sharedPreferences = await SharedPreferences.getInstance();
      yield ScopeProgress(progressIterator.nextProgress());

      analytics = FakeAnalytics();
      await analytics.init();
      yield ScopeProgress(progressIterator.nextProgress());

      httpClient = FakeAppHttpClient();
      await httpClient.init();
      yield ScopeProgress(progressIterator.nextProgress());

      service = FakeService();
      await service.init();
      yield ScopeProgress(progressIterator.nextProgress());

      yield ScopeReady(
        AppDependencies(
          sharedPreferences: sharedPreferences,
          httpClient: httpClient,
          service: service,
          analytics: analytics,
        ),
      );

      isInitialized = true;
    } finally {
      if (!isInitialized) {
        await [
          httpClient?.close(),
          service?.dispose(),
          analytics?.dispose(),
        ].nonNulls.wait;
      }
    }
  }

  @override
  Future<void> dispose() async {
    await [
      httpClient.close(),
      service.dispose(),
      analytics.dispose(),
    ].wait;
  }
}
