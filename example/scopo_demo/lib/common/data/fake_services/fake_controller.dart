import '../../../utils/app_environment.dart';

class FakeController {
  Future<void> init() async {
    await Future<void>.delayed(AppEnvironment.defaultInitPause);
    if (AppEnvironment.errorOnFakeControllerInit) {
      throw Exception('$FakeController init error');
    }
  }

  Future<void> dispose() async {
    await Future<void>.delayed(AppEnvironment.defaultDisposePause);
    if (AppEnvironment.errorOnFakeControllerDispose) {
      throw Exception('$FakeController dispose error');
    }
  }
}
