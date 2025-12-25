# scopo

A robust Flutter package for managing scopes, dependency injection, and asynchronous initialization in your widget tree.

`scopo` simplifies the process of creating hierarchical scopes where dependencies can be initialized, accessed, and disposed of automatically. It handles loading states, errors, and provides a clean API for accessing dependencies and UI state, with built-in support for smooth closing transitions.

## Features

- **Scoped Dependency Injection**: Efficiently provide and access dependencies down the widget tree.
- **Asynchronous Initialization**: Built-in support for both `Stream` and `Future` based initialization with progress reporting.
- **Lifecycle Management**: Automatically disposes of dependencies when the scope is closed.
- **Closing Transition**: **[NEW]** Captures a screenshot of the scope before closing to ensure a smooth transition and prevent UI flickering during disposal.
- **Separation of Concerns**: Clearly separates Dependencies (`ScopeDependencies`), UI Logic (`ScopeState`), and Wiring (`Scope`).
- **Flexible Providers**: Includes `ScopeModel` for general values and `ScopeNotifier` for `Listenable`s / `ChangeNotifier`s.

## Installation

Add `scopo` to your `pubspec.yaml`:

```yaml
dependencies:
  scopo: ^0.2.2
```

## Core Concepts

`scopo` revolves around three main components:

1.  **ScopeDependencies**: The dependencies associated with a scope.
2.  **ScopeState**: The UI logic and state (extends `ScopeState`).
3.  **Scope**: The widget that wires everything together.

### 1. Define Dependencies

Create a class that implements `ScopeDependencies`. This is where you initialize your services.

```dart
class MyFeatureDeps implements ScopeDependencies {
  final ApiService api;
  final Database db;

  MyFeatureDeps(this.api, this.db);

  static Stream<ScopeInitState<double, MyFeatureDeps>> init() async* {
    // 1. Init API
    final api = ApiService();
    await api.init();
    yield ScopeProgress(0.5);

    // 2. Init DB
    final db = Database();
    await db.open();
    yield ScopeProgress(1.0);

    // 3. Ready
    yield ScopeReady(MyFeatureDeps(api, db));
  }

  @override
  Future<void> dispose() async {
    await db.close();
    await api.dispose();
  }
}
```

### 2. Define Content

Create a class extending `ScopeContent`.

```dart
class MyFeatureContent extends ScopeContent<MyScope, MyFeatureDeps, MyFeatureContent> {

  void doSomething() {
    deps.api.fetch(); // Access dependencies
    notifyListeners(); // Rebuild UI
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("My Feature"));
  }
}
```

### 3. Define the Scope

Create your Scope widget. This is where you configure initialization and behavior.

```dart
class MyScope extends Scope<MyScope, MyFeatureDeps, MyFeatureContent> {
  const MyScope({
    super.key,
    // Optional: Ensure only one instance exists in the tree
    super.onlyOneInstance = false,
    // Optional: Pause after init (e.g. for splash screens)
    super.pauseAfterInitialization,
  }) : super(init: MyFeatureDeps.init);

  static MyFeatureDeps of(BuildContext context) =>
      Scope.of<MyScope, MyFeatureDeps, MyFeatureContent>(context).dependencies;

  @override
  MyFeatureContent createContent() => MyFeatureContent();

  @override
  Widget buildOnInitializing(BuildContext context, Object? progress) {
    return CircularProgressIndicator(value: progress as double?);
  }

  @override
  Widget buildOnError(BuildContext context, Object error, StackTrace stack, Object? progress) {
    return Text("Error: $error");
  }

  // Optional: Custom disposal timeout
  @override
  Duration? get disposeTimeout => const Duration(seconds: 5);
}
```

## Advanced Usage

### Closing Transition

When `Scope.close()` is called (usually via `NavigationNode` on pop), `scopo` automatically:
1.  Captures a screenshot of the current UI.
2.  Displays the screenshot on top.
3.  Runs the `dispose` logic of your dependencies.
4.  Removes the scope once disposal is complete (or times out).

This prevents "black screens" or broken UI while async disposal is happening.

### Simple Dependency Injection

If you don't need a full Scope with initialization logic, use `ScopeModel` or `ScopeNotifier`.

**ScopeModel** (Generic value provider):
```dart
ScopeModel<MyService>(
  create: (context) => MyService(),
  dispose: (service) => service.close(), // Optional
  builder: (context) => ChildWidget(),
)
```

**ScopeNotifier** (For Listenable/ChangeNotifier):
```dart
ScopeNotifier<MyController>(
  create: (context) => MyController(),
  dispose: (controller) => controller.dispose(),
  builder: (context) => ChildWidget(),
)
```

Accessing values:
```dart
final service = ScopeModel.of<MyService>(context, listen: true);
// or
final controller = ScopeNotifier.of<MyController>(context, listen: true);
```

### Async Initializer

If you just need to wait for a Future before showing a widget:

```dart
ScopeAsyncInitializer<String>(
  init: () async {
    await Future.delayed(Duration(seconds: 1));
    return "Hello";
  },
  buildOnInitializing: (context) => CircularProgressIndicator(),
  buildOnReady: (context, value) => Text(value),
  buildOnError: (context, error, stack) => Text("Error"),
  dispose: (value) => print("Disposed $value"),
)
```

### NavigationNode

Use `NavigationNode` to handle nested navigation within a scope, ensuring that pushed routes (including dialogs and bottom sheets) still have access to the scope's dependencies.

```dart
NavigationNode(
  onPop: (context, result) async {
    // Determine if scope should close
    await MyScope.of(context).close();
    return true;
  },
  child: MyContent(),
)
```

## Utilities

-   **ListenableSelector**: Rebuild only when specific parts of a Listenable change.
-   **logging**: Configure logs via `ScopeConfig.log` and `ScopeConfig.logError`.
