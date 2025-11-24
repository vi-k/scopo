import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(App(init: AppDeps.init));
}

final class App extends Scope<App, AppDeps, AppContent> {
  const App({
    super.key,
    required ScopeInitFunction<String, AppDeps> super.init,
  });

  static App paramsOf(BuildContext context, {bool listen = true}) =>
      Scope.paramsOf<App, AppDeps, AppContent>(context, listen: listen);

  static AppContent of(BuildContext context) =>
      Scope.of<App, AppDeps, AppContent>(context);

  Widget _app(Widget child) {
    return MaterialApp(
      title: 'Scope demo',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
      )),
      home: child,
    );
  }

  @override
  Widget onInit(Object? progress) =>
      _app(_SplashScreen(progress: progress as String?));

  @override
  Widget onError(Object error, StackTrace stackTrace) =>
      _app(_ErrorScreen(error: error));

  @override
  Widget wrapContent(AppDeps deps, Widget child) => _app(child);

  @override
  AppContent createContent() => AppContent();

  @override
  bool updateParamsShouldNotify(App oldWidget) => false;
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.progress});

  final String? progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(progress ?? ''),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '$error',
          style: DefaultTextStyle.of(context)
              .style
              .copyWith(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

class AppDeps implements ScopeDeps {
  final SharedPreferences sharedPreferences;

  AppDeps({
    required this.sharedPreferences,
  });

  static Stream<ScopeInitState<String, AppDeps>> init(
    BuildContext context,
  ) async* {
    SharedPreferences? sharedPreferences;

    yield ScopeProgress('init $SharedPreferences');
    sharedPreferences = await SharedPreferences.getInstance();

    await Future<void>.delayed(const Duration(milliseconds: 500));

    yield ScopeReady(
      AppDeps(
        sharedPreferences: sharedPreferences,
      ),
    );
  }

  @override
  Future<void> dispose() async {}
}

final class AppContent extends ScopeContent<App, AppDeps, AppContent> {
  late int _counter;
  int get counter => _counter;

  @override
  void initState() {
    super.initState();
    _counter = App.of(context).deps.sharedPreferences.getInt('counter') ?? 0;
  }

  Future<void> increment() async {
    _counter++;
    notifyListeners();
    await App.of(context).deps.sharedPreferences.setInt('counter', _counter);
  }

  @override
  Widget build(BuildContext context) => HomeScreen();
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: App.of(context),
        builder: (context, _) => Center(
          child: Text('${App.of(context).counter}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: App.of(context).increment,
        child: Icon(Icons.add),
      ),
    );
  }
}
