import '../../../utils/app_environment.dart';

class Analytics {
  const Analytics();

  Future<void> init() async {
    await Future<void>.delayed(AppEnvironment.defaultPause);
  }

  Future<void> dispose() async {
    //
  }
}
