import 'dart:async';

import '../../../utils/app_environment.dart';

class FakeService {
  Future<void> init() async {
    await Future<void>.delayed(AppEnvironment.defaultInitPause);
    if (AppEnvironment.errorOnFakeServiceInit) {
      throw Exception('$FakeService init error');
    }
  }

  Future<void> dispose() async {
    await Future<void>.delayed(AppEnvironment.defaultDisposePause);
    if (AppEnvironment.errorOnFakeServiceDispose) {
      throw Exception('$FakeService dispose error');
    }
  }
}
