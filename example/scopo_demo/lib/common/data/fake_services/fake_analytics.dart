import '../../../utils/app_environment.dart';

class FakeAnalytics {
  Future<void> init() async {
    await Future<void>.delayed(AppEnvironment.defaultInitPause);
    if (AppEnvironment.errorOnFakeAnalyticsInit) {
      throw Exception('$FakeAnalytics init error');
    }
  }

  Future<void> dispose() async {
    await Future<void>.delayed(AppEnvironment.defaultDisposePause);
    if (AppEnvironment.errorOnFakeAnalyticsDispose) {
      throw Exception('$FakeAnalytics dispose error');
    }
  }
}
