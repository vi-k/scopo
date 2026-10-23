import 'manifest.dart';

/// The blocks of the `debug` topic.
const debugTopic = DocManifest(
  'doc/debug.md',
  support: _support,
  {
    'the-observer/main': _library,
    'the-observer/CrashReporter': _library,
    'the-observer/scopeconfig-observer-const-sco': DocEnvironment(
      '$_application\nfinal class CrashReporter extends ScopeObserver {\n'
          'const CrashReporter();\n}\nvoid example() {',
      '}',
    ),
    'who-the-event-is-about/ScopeAnalytics': _library,
    'scopeprintobserver/scopeconfig-observer-const-sco': _body,
    'scopeprintobserver/scopeconfig-observer-scopeprin': _body,
    'timeouts/asyncscope': DocEnvironment.skip(
      'Constructor outline with an ellipsis in place of the remaining arguments.',
    ),
    'reset/main': DocEnvironment.skip(
      'Test setup outline with an ellipsis in place of the test declarations.',
    ),
    'in-tests/RecordingObserver': DocEnvironment(
      "import 'package:flutter_test/flutter_test.dart';\n$_application",
      '',
    ),
    'coming-from-0-12-x/AfterObserver': _library,
  },
);

const _library = DocEnvironment(_application, '');
const _body = DocEnvironment('void example() {', '}');
const _support = '''
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:scopo/scopo.dart';
''';
const _application = '''
class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final class CounterScope extends AsyncScopeBase<CounterScope> {
  const CounterScope({super.key, super.tag});
  @override
  Future<void> initScope(BuildContext context, ScopeInitContext ctx) async {}
  @override
  void disposeScope() {}
  @override
  Widget buildOnProgress(BuildContext context, Object? progress) =>
      const SizedBox.shrink();
  @override
  Widget buildOnError(BuildContext context, Object error, StackTrace stack,
      Object? progress) => const SizedBox.shrink();
  @override
  Widget buildOnReady(BuildContext context) => const SizedBox.shrink();
}

final crashlytics = Crashlytics();
class Crashlytics {
  void recordError(Object error, StackTrace? stackTrace,
      {required String reason}) {}
}

final analytics = Analytics();
class Analytics {
  void logEvent(String name, Map<String, String> parameters) {}
}
''';
