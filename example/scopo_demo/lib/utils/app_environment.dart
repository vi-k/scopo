// ignore: avoid_classes_with_only_static_members
abstract final class AppEnvironment {
  static double probabilityOfAppRandomError = 0;
  static double probabilityOfHomeRandomError = 0;

  static (int, int) enabledConnectionDuration = (10, 20);
  static (int, int) disabledConnectionDuration = (10, 20);

  static Duration defaultPause = const Duration(milliseconds: 300);
}
