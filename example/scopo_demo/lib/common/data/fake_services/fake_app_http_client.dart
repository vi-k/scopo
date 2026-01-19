import '../../../utils/app_environment.dart';

class FakeAppHttpClient {
  Future<void> init() async {
    await Future<void>.delayed(AppEnvironment.defaultInitPause);
    if (AppEnvironment.errorOnFakeAppHttpClientInit) {
      throw Exception('$FakeAppHttpClient init error');
    }
  }

  Future<void> close() async {
    await Future<void>.delayed(AppEnvironment.defaultDisposePause);
    if (AppEnvironment.errorOnFakeAppHttpClientClose) {
      throw Exception('$FakeAppHttpClient close error');
    }
  }
}
