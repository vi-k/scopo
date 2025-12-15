// ignore: avoid_classes_with_only_static_members
abstract final class CompareUtils {
  static bool equals(Object? a, Object? b) => a == b;

  static bool notEquals(Object? a, Object? b) => a != b;

  static bool identical(Object? a, Object? b) => identical(a, b);

  static bool notIdentical(Object? a, Object? b) => !identical(a, b);
}
