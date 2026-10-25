import 'manifest.dart';

/// The blocks of the package README.
const readme = DocManifest(
  'README.md',
  support: _support,
  {
    'installation/import-package-scopo-scopo-dar': _library,
    'the-families/ApiConfig': _library,
    'the-families/UserGate': _library,
    'the-families/CounterGate': _library,
    'the-families/ConnectionGate': DocEnvironment(_home, _application),
    'the-families/DatabaseGate': _library,
    'the-families/Player': _library,
    'the-families/ScreenScope': _library,
    'scope-the-full-family/AppDependencies': _library,
    'scope-the-full-family/AppState':
        DocEnvironment('$_dependencies\n$_app\n$_home', _application),
    'scope-the-full-family/App':
        DocEnvironment('$_dependencies\n$_state', _application),
    'scope-the-full-family/HomeScreen':
        DocEnvironment('$_dependencies\n$_state\n$_app', _application),
    'accessors-the-type-arguments-o/static-v-select-v-buildcontext':
        DocEnvironment(
      '$_dependencies\n$_state\n$_app\nclass Accessors {',
      '}$_application',
    ),
    'accessors-the-type-arguments-o/App': DocEnvironment.skip(
      'Class skeleton contains an ellipsis in place of its remaining members.',
    ),
    'scopekey/scopeconfig-defaultscopekeytim':
        DocEnvironment('void example() {', '}'),
    'scopekey/asyncscopecoordinator-child-ma':
        DocEnvironment('$_home\nWidget example() =>', ';$_application'),
    'scopekey/await-asyncscopecoordinator-wa': DocEnvironment(
      'Future<void> example(BuildContext context) async {',
      '}$_application',
    ),
    'closing-in-place/CloseDatabaseButton': _library,
    'observing-and-configuration/main':
        DocEnvironment('$_dependencies\n$_state\n$_app', _application),
    'observing-and-configuration/CrashReporter': _library,
    'testing/late-recordingobserver-observe': DocEnvironment(
      // The test runner supplies these registration callbacks.
      'void example(void Function(void Function()) setUp, '
          'void Function(void Function()) tearDown) {',
      '}$_application',
    ),
  },
);

const _library = DocEnvironment('', _application);

// Only the application companions missing from each independent block.
const _dependencies = '''
class AppDependencies implements ScopeDependencies {
  final sharedPreferences = SharedPreferences();
  static Future<AppDependencies> init(ScopeInitContext ctx) async =>
      AppDependencies();
  @override
  void onUnmount() {}
  @override
  Future<void> dispose() async {}
}
''';
const _state = '''
final class AppState extends ScopeState<App, AppDependencies, AppState> {
  int get counter => 0;
  Future<void> increment() async {}
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
const _app = '''
final class App extends Scope<App, AppDependencies, AppState> {
  final String title;
  const App({super.key, required this.title});
  @override
  Future<AppDependencies> initDependencies(
    BuildContext context, ScopeInitContext ctx,
  ) => AppDependencies.init(ctx);
  @override
  AppState createState() => AppState();
  @override
  Widget buildOnProgress(BuildContext context, Object? progress) =>
      const SizedBox();
  @override
  Widget buildOnError(BuildContext context, Object error, StackTrace stack,
      Object? progress) => const SizedBox();
  static AppState of(BuildContext context) =>
      Scope.of<App, AppDependencies, AppState>(context);
  static V select<V>(BuildContext context, V Function(AppState) selector) =>
      Scope.select<App, AppDependencies, AppState, V>(context, selector);
  static V selectParam<V>(BuildContext context, V Function(App) selector) =>
      Scope.selectParam<App, AppDependencies, AppState, V>(context, selector);
}
''';
const _home = '''
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
const _support = '''
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';
''';
const _application = r'''
class UserModel {
  UserModel(this.name);
  final String name;
  void dispose() {}
}

class Counter extends ChangeNotifier {
  int value = 0;
  void increment() {
    value++;
    notifyListeners();
  }
}

final connection = Connection();
class Connection {
  Future<void> open() async {}
  Future<void> close() async {}
}

class Database {
  static Future<Database> open() async => Database();
  Future<void> close() async {}
}

class DatabaseView extends StatelessWidget {
  const DatabaseView({super.key, required this.database});
  final Database database;
  @override
  Widget build(BuildContext context) => Text('$database');
}

class Track {}
void _onTrack(Track track) {}
class Api {
  Future<Session> openSession() async => Session();
  Future<void> closeSession() async {}
}
class Session {
  Stream<Track> get tracks => const Stream.empty();
}

class SharedPreferences {
  static Future<SharedPreferences> getInstance() async => SharedPreferences();
  int? getInt(String key) => null;
  Future<bool> setInt(String key, int value) async => true;
}

class RecordingObserver extends ScopeObserver {}

final crashlytics = Crashlytics();
class Crashlytics {
  void recordError(Object error, StackTrace? stackTrace,
      {required String reason}) {}
}
''';
