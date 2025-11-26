# scopo

A Flutter package for managing scopes, dependency injection, and asynchronous
initialization in your widget tree.

`scopo` simplifies the process of creating hierarchical scopes where
dependencies can be initialized, accessed, and disposed of automatically.
It handles loading states, errors, and provides a clean API for accessing
dependencies and UI state.

## Features

- **Scoped Dependency Injection**: easily provide and access dependencies down
  the widget tree.
- **Asynchronous Initialization**: built-in support for async dependency
  initialization with progress reporting.
- **Lifecycle Management**: automatically disposes of dependencies when the
  scope is closed.
- **Error Handling**: graceful handling of initialization errors.
- **Separation of Concerns**: clearly separates Dependencies (`ScopeDeps`),
  UI Logic (`ScopeContent`), and Wiring (`Scope`).

## Installation

Add `scopo` to your `pubspec.yaml`:

```yaml
dependencies:
  scopo: ^0.2.1
```

Or run:

```bash
flutter pub add scopo
```

## Usage

Using `scopo` involves three main steps: defining your dependencies, defining
your content (UI/Logic), and creating the `Scope` widget.

### 1. Define Dependencies

Create a class that implements `ScopeDeps`. This class holds your services,
repositories, etc. Implement the static `init` method to initialize them.

```dart
import 'package:scopo/scopo.dart';

class MyFeatureDeps implements ScopeDeps {
  final ApiService apiService;
  final Database db;

  MyFeatureDeps({required this.apiService, required this.db});

  // The initialization logic.
  static Stream<ScopeInitState<double, MyFeatureDeps>> init() async* {
    ApiService? apiService;
    Database? db;
    var _isInitialized = false;

    try {
      // 1. Initialize API Service.
      apiService = ApiService();
      await apiService.init();
      yield ScopeProgress(0.5); // Report progress 50%

      // 2. Initialize Database.
      final db = Database();
      await db.open();
      yield ScopeProgress(1.0); // Report progress 100%

      // 3. Ready!
      yield ScopeReady(
        MyFeatureDeps(
          apiService: apiService,
          db: db,
        ),
      );

      _isInitialized = true;
    } finally {
      // Clean up in case of error or cancellation.
      if (!_isInitialized) {
        await db?.close();
        await apiService?.dispose();
      }
    }
  }

  @override
  Future<void> dispose() async {
    // Clean up.
    await db.close();
    await apiService.dispose();
  }
}
```

### 2. Define Content

Create a class that extends `ScopeContent`. This is where your UI logic and
state reside. It has access to the dependencies.

```dart
class MyFeatureContent extends ScopeContent<MyFeatureScope, MyFeatureDeps, MyFeatureContent> {
  @override
  void initState() {
    super.initState();
    ...
  }

  // Access dependencies via `deps`.
  void fetchData() {
    deps.apiService.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Feature')),
      body: Center(child: Text('Feature Content')),
    );
  }
}
```

### 3. Define the Scope

Create a widget that extends `Scope`. This connects the dependencies and the
content.

```dart
class MyFeatureScope extends Scope<MyFeatureScope, MyFeatureDeps, MyFeatureContent> {
  const MyFeatureScope({super.key}) : super(init: MyFeatureDeps.init);

  // Boilerplate for easy access.
  static MyFeatureContent of(BuildContext context) =>
      Scope.of<MyFeatureScope, MyFeatureDeps, MyFeatureContent>(context);

  @override
  MyFeatureContent createContent() => MyFeatureContent();

  // Loading screen.
  @override
  Widget onInit(Object? progress) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          value: progress as double?,
        ),
      ),
    );
  }

  // Error screen.
  @override
  Widget onError(Object error, StackTrace stackTrace) {
    return Scaffold(
      body: Center(
        child: Text('Error: $error'),
      ),
    );
  }

  @override
  bool updateParamsShouldNotify(MyFeatureScope oldWidget) => false;
}
```

### 4. Use it

Simply wrap your widget tree (or part of it) with your `Scope`.

```dart
void main() {
  runApp(
    const MaterialApp(
      home: MyFeatureScope(),
    ),
  );
}
```

## Accessing Dependencies

You can access the scope and its dependencies from any child widget:

```dart
// Get the content (and dependencies via content.deps)
final content = Scope.of<MyFeatureScope, MyFeatureDeps, MyFeatureContent>(context);

// Or if you added the helper method in your `Scope` class:
final deps = MyFeatureScope.of(context).deps;
```

## Examples

Check out the `example` directory for more comprehensive examples:

-   **minimal**: A simple counter app demonstrating basic usage.
-   **scopo_demo**: A more complex app with nested scopes, error simulation, and custom progress indicators.
