import '../../../utils/app_environment.dart';

class HttpClient {
  const HttpClient();

  Future<void> init() async {
    await Future<void>.delayed(AppEnvironment.defaultPause);
  }

  Future<void> dispose() async {
    await Future<void>.delayed(AppEnvironment.defaultPause);
  }
}
