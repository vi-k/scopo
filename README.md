# scopo

> [!WARNING]
> Description needs updating!

A robust Flutter package for managing scopes, dependency injection, and state management within the widget tree. `scopo` provides a clean, extensive API for handling dependencies and state with a focus on lifecycle management and async initialization.

## Features

- **Scope Management**: defining scopes that hold dependencies and state.
- **Dependency Injection**: Access dependencies effortlessly down the widget tree.
- **State Management**: Built-in state management linked to scopes.
- **Async Initialization**: Robust handling of async dependency initialization with loading and error states.
- **Specialized Scopes**: specialized widgets for simple values, models, and listenables.
- **Selectors**: Efficient rebuilding of widgets by selecting specific parts of state or dependencies.

## Core Concepts

### Scope

The `Scope` widget is the foundation of the package. It manages:
1.  **Dependencies**: An extended class of `ScopeDependencies`.
2.  **State**: An extended class of `ScopeState`.

It handles the lifecycle of dependencies (initialization and disposal) and provides them to its descendants.

#### 1. Define Dependencies

Create a class implementing `ScopeDependencies`.

```dart
class AppDependencies implements ScopeDependencies {
  final SharedPreferences sharedPreferences;

  AppDependencies({required this.sharedPreferences});

  // Initialization logic
  static Stream<ScopeInitState<String, AppDependencies>> init() async* {
    yield ScopeProgress('Initializing Storage...');
    final sharedPreferences = await SharedPreferences.getInstance();
    yield ScopeReady(AppDependencies(sharedPreferences: sharedPreferences));
  }

  @override
  Future<void> dispose() async {
    // Dipose resources if needed
  }
}
```

#### 2. Define State

Create a class extending `ScopeState`.

```dart
final class AppState extends ScopeState<App, AppDependencies, AppState> {
  int _counter = 0;
  int get counter => _counter;

  void increment() {
    _counter++;
    notifyDependents();
  }

  @override
  Widget build(BuildContext context) => HomeScreen();
}
```

#### 3. Create the Scope

```dart
final class App extends Scope<App, AppDependencies, AppState> {
  const App({super.key});

  @override
  Stream<ScopeInitState<String, AppDependencies>> init(BuildContext context) =>
      AppDependencies.init();

  @override
  AppState createState() => AppState();

  // Initialization UI handlers
  @override
  Widget buildOnInitializing(
    BuildContext context,
    covariant String? progress,
  ) =>
      const CircularProgressIndicator();

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stack,
    covariant String? progress,
  ) =>
      Text('Error: $error');

  // Helper accessors
  static AppState of(BuildContext context) =>
      Scope.of<App, AppDependencies, AppState>(context);

  static V select<V>(BuildContext context, V Function(AppState state) selector) =>
      Scope.select<App, AppDependencies, AppState, V>(context, selector);
}
```

## Specialized Scopes

`scopo` provides lightweight alternatives for specific use cases.

### ScopeWidget

Inject a simple generic value or widget-specific data down the tree.

```dart
class MyConfig extends ScopeWidgetBase<MyConfig> {
  final String apiKey;
  final Widget child;

  const MyConfig({required this.apiKey, required this.child});

  @override
  Widget build(BuildContext context) => child;

  static MyConfig of(BuildContext context) =>
      ScopeWidgetBase.of<MyConfig>(context, listen: false);
}
```

### ScopeModel

Inject a pure Dart class (Model) that doesn't need the full overhead of a `Scope`.

```dart
class UserModel {
  final String name;

  UserModel(this.name);

  void dispose() {
    // Dipose resources if needed
  }
}

// In widget tree
ScopeModel<UserModel>(
  create: (context) => UserModel('Alice'),
  dispose: (model) => model.dispose(),
  builder: (context) => ConsumerWidget(),
)

// Access
final user = ScopeModel.of<UserModel>(context, listen: true);
```

### ScopeNotifier

Automatically manage `Listenable`s (like `ChangeNotifier` or `ValueNotifier`).

```dart
class Counter extends ValueNotifier<int> {
  Counter() : super(0);
}

// In widget tree
ScopeNotifier<Counter>(
  create: (context) => Counter(),
  dispose: (model) => model.dispose(),
  builder: (context) => CounterView(),
)
```

### ScopeAsyncInitializer

Handle single-shot asynchronous initialization.

```dart
ScopeAsyncInitializer<Database>(
  init: () async => await openDatabase(),
  buildOnInitializing: (context) => LoadingScreen(),
  buildOnReady: (context, database) => AppContent(database: database),
)
```

### ScopeStreamInitializer

Handle stream-based initialization, useful for reporting progress during startup.

```dart
ScopeStreamInitializer<AppDeps>(
  init: () async* {
    yield ScopeProgress('Loading...');
    // ... load resources
    yield ScopeReady(deps);
  },
  buildOnInitializing: (context, progress) => LoadingScreen(msg: progress),
  buildOnReady: (context, deps) => AppHome(),
)
```

## Usage

### Accessing Data

You can access the Scope's State or Dependencies using `Scope.of` or static helpers you define.

```dart
// Get State (listen: true by default)
final appState = App.of(context);

// Select specific value to minimize rebuilds
final counter = App.select(context, (state) => state.counter);
```
