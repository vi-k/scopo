import '../../../utils/app_environment.dart';

class SomeController {
  Future<void> init() async {
    await Future<void>.delayed(AppEnvironment.defaultPause);
  }

  Future<void> dispose() async {
    await Future<void>.delayed(AppEnvironment.defaultPause);
  }
}
