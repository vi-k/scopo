import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Collects what reaches `FlutterError.onError` for the rest of a `test`,
/// instead of letting it print over the test output; the previous handler is
/// given back in a tear-down.
///
/// Not for `testWidgets`: the binding checks that the handler is back before
/// the tear-downs run, so a widget test gives it back in its own body, before
/// the expectations.
List<Object> recordFlutterErrors() {
  final reported = <Object>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => reported.add(details.exception);
  addTearDown(() => FlutterError.onError = previous);
  return reported;
}
