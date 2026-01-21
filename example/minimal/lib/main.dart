import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(App(init: AppDependencies.init));
}

final class App extends Scope<App, AppDependencies, AppState> {
  final ScopeInitFunction<String, AppDependencies> init;

  const App({super.key, required this.init});

  @override
  Stream<ScopeInitState<String, AppDependencies>> initDependencies(
    BuildContext context,
  ) =>
      init(context);

  static App paramsOf(BuildContext context, {bool listen = true}) =>
      Scope.paramsOf<App, AppDependencies, AppState>(context, listen: listen);

  static AppState of(BuildContext context) =>
      Scope.of<App, AppDependencies, AppState>(context);

  static V select<V extends Object?>(
    BuildContext context,
    V Function(AppState state) selector,
  ) =>
      Scope.select<App, AppDependencies, AppState, V>(
        context,
        (state) => selector(state),
      );

  Widget _app({required Widget child}) {
    return MaterialApp(
      title: 'scopo minimal demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: child,
    );
  }

  @override
  Widget buildOnInitializing(BuildContext context, Object? progress) =>
      _app(child: _SplashScreen(progress: progress as String?));

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) =>
      _app(child: _ErrorScreen(error: error));

  @override
  Widget wrapState(
    BuildContext context,
    AppDependencies dependencies,
    Widget child,
  ) =>
      _app(child: child);

  @override
  AppState createState() => AppState();
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.progress});

  final String? progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(progress ?? '')));
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.error,
      body: Center(
        child: Text(
          '$error',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
        ),
      ),
    );
  }
}

class AppDependencies implements ScopeDependencies {
  final SharedPreferences sharedPreferences;

  AppDependencies({required this.sharedPreferences});

  static Stream<ScopeInitState<String, AppDependencies>> init(_) async* {
    SharedPreferences? sharedPreferences;

    yield ScopeProgress('init $SharedPreferences');
    sharedPreferences = await SharedPreferences.getInstance();

    await Future<void>.delayed(const Duration(milliseconds: 500));

    yield ScopeReady(AppDependencies(sharedPreferences: sharedPreferences));
  }

  @override
  Future<void> dispose() async {}
}

final class AppState extends ScopeState<App, AppDependencies, AppState> {
  late int _counter;
  int get counter => _counter;

  @override
  void initState() {
    super.initState();
    _counter =
        App.of(context).dependencies.sharedPreferences.getInt('counter') ?? 0;
  }

  Future<void> increment() async {
    _counter++;
    notifyDependents();
    await App.of(
      context,
    ).dependencies.sharedPreferences.setInt('counter', _counter);
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen();
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = App.select(context, (state) => state.counter);

    return Scaffold(
      body: Center(
        child: Text(
          '$counter',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: App.of(context).increment,
        child: Icon(Icons.add),
      ),
    );
  }
}
