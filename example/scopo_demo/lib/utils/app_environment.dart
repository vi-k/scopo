// ignore: avoid_classes_with_only_static_members
abstract final class AppEnvironment {
  static Duration defaultInitPause = const Duration(milliseconds: 300);
  static Duration defaultDisposePause = const Duration(milliseconds: 300);

  static bool errorOnFakeAnalyticsInit = false;
  static bool errorOnFakeAnalyticsDispose = false;

  static bool errorOnFakeAppHttpClientInit = false;
  static bool errorOnFakeAppHttpClientClose = false;

  static bool errorOnFakeServiceInit = false;
  static bool errorOnFakeServiceDispose = false;

  static bool errorOnFakeUserHttpClientInit = false;
  static bool errorOnFakeUserHttpClientClose = false;

  static bool errorOnFakeBlocLoading = false;

  static bool errorOnFakeControllerInit = false;
  static bool errorOnFakeControllerDispose = false;
}
