import '../../../utils/app_environment.dart';

class FakeUserHttpClient {
  Future<void> init() async {
    await Future<void>.delayed(AppEnvironment.defaultInitPause);
    if (AppEnvironment.errorOnFakeUserHttpClientInit) {
      throw Exception('$FakeUserHttpClient init error');
    }
  }

  Future<void> close() async {
    await Future<void>.delayed(AppEnvironment.defaultDisposePause);
    if (AppEnvironment.errorOnFakeUserHttpClientClose) {
      throw Exception('$FakeUserHttpClient close error');
    }
  }
}
