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

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [1. Define Dependencies](#1-define-dependencies)
  - [2. Define Content](#2-define-content)
  - [3. Define the Scope](#3-define-the-scope)
  - [4. Use it](#4-use-it)
- [Accessing Dependencies](#accessing-dependencies)
- [Logging](#logging)
- [Utilities](#utilities)
  - [ScopeConsumer](#scopeconsumer)
  - [NavigationNode](#navigationnode)
  - [DoubleProgressIterator](#doubleprogressiterator)
  - [IntProgressIterator](#intprogressiterator)
  - [ListenableListenExtension](#listenablelistenextension)
  - [ListenableSelectExtension](#listenableselectextension)
  - [ListenableSelector](#listenableselector)
- [Examples](#examples)

## Installation

Add `scopo` to your `pubspec.yaml`:

```yaml
dependencies:
  scopo: ^0.2.2
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

`ScopeContent` implements `Listenable`, so you can use it to rebuild widgets
when state changes (e.g. using `ListenableBuilder` or `ListenableSelector`).

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

  // Notify listeners to rebuild widgets that listen to this content.
  void updateState() {
    notifyListeners();
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

## Logging

You can enable and customize logging using `ScopeConfig`.

```dart
void main() {
  // Enable debug logs
  ScopeConfig.debug.isEnabled = true;

  // Enable error logs
  ScopeConfig.debugError.isEnabled = true;

  // Customize logger
  ScopeConfig.debug.log = (source, message, error, stackTrace) {
    print('[$source] $message');
  };

  runApp(const MyApp());
}
```

## Utilities

### ScopeConsumer

A mixin for `State` classes that provides easy access to the scope content.

```dart
class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget>
    with ScopeConsumer<MyFeatureScope, MyFeatureDeps, MyFeatureContent> {
  @override
  Widget build(BuildContext context) {
    // Access scope content via `scope`
    return Text(scope.someValue);
  }
}
```

Or:

```dart

typedef MyFeatureConsumer =
    ScopeConsumer<MyFeatureScope, MyFeatureDeps, MyFeatureContent>;

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with MyFeatureConsumer {
  @override
  Widget build(BuildContext context) {
    // Access scope content via `scope`
    return Text(scope.someValue);
  }
}
```

### NavigationNode

A widget that creates a nested `Navigator`. It allows you to include bottom
sheets, dialogs, and other screens in the current scope, ensuring they have
access to the dependencies.

```dart
final class MyFeature extends Scope<MyFeature, MyFeatureDeps, MyFeatureContent> {
  const MyFeature({super.key});

  ...

  @override
  Widget wrapContent(MyFeatureDeps deps, Widget child) => NavigationNode(
    onPop: (context, result) async {
      await MyFeature.of(context).close();
      return true;
    },
    child: child,
  );
}

final class MyFeatureContent
    extends ScopeContent<MyFeature, MyFeatureDeps, MyFeatureContent> {
  String get nestedScreenTitle = 'My Nested Screen';

  @override
  Widget build(BuildContext context) {
    return MyNestedScreen();
  }
}

// Because of `NavigationNode`, this screen will be pushed to the nested
// navigator and will have access to `MyFeatureContent` and `MyFeatureDeps`.
class MyNestedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // This dialog will be pushed to the nested navigator too and will
            // have access to `MyFeatureContent` and `MyFeatureDeps`.
            showDialog(
              context: context,
              // But you must specify not to use the root navigator!
              useRootNavigator: false,
              builder: (context) {
                // Access dependencies!
                final deps = MyFeature.of(context).deps;
                return AlertDialog(title: Text('Deps: $deps'));
              },
            );
          },
          child: Text(MyFeature.of(context).nestedScreenTitle),
        ),
      ),
    );
  }
}
```

### DoubleProgressIterator

A helper class to track initialization progress as a `double` value between 0.0 and 1.0.

```dart
static Stream<ScopeInitState<double, MyFeatureDeps>> init() async* {
  final progressIterator = DoubleProgressIterator(count: 3);

  // step 1
  yield ScopeProgress(progressIterator.nextProgress()); // 0.33

  // step 2
  yield ScopeProgress(progressIterator.nextProgress()); // 0.66

  // step 3
  yield ScopeProgress(progressIterator.nextProgress()); // 1.0

  ...
}
```

### IntProgressIterator

A helper class to track initialization progress as an `int` value.

```dart
static Stream<ScopeInitState<int, MyFeatureDeps>> init() async* {
  final progressIterator = IntProgressIterator(count: 3);

  // step 1
  yield ScopeProgress(progressIterator.nextStep()); // 1

  // step 2
  yield ScopeProgress(progressIterator.nextStep()); // 2

  // step 3
  yield ScopeProgress(progressIterator.nextStep()); // 3

  ...
}
```

### ListenableListenExtension

A helper extension that adds a `listen` method to `Listenable`, similar to
`Stream.listen`. It returns a `ListenableSubscription` that can be easily
canceled.

```dart
final scrollController = ScrollController();
final subscription = scrollController.listen(() {
  // ...
});

// ...

subscription.cancel();
```

It also supports `CompositeListenableSubscription` for managing multiple
subscriptions:

```dart
final composite = CompositeListenableSubscription();

composite.add(listenable1.listen(listener1));
listenable2.listen(listener2).addTo(composite);

// ...

composite.cancel();
```

### ListenableSelectExtension

A helper extension that adds a `select` method to `Listenable`. It allows
listening to a specific value of the `Listenable` (selector), triggering the
listener only when that value changes.

```dart
final subscription = listenable.select(
  (listenable) => listenable.value,
  (listenable, value) => print(value),
);
```

By default, the previous value is compared to the new value using the
operator `==`, but this behavior can be changed using `compare`.

```dart
final subscription = listenable.select(
  (listenable) => listenable.value,
  (listenable, value) => print(value),
  compare: (previous, current) => identical(previous, current),
);
```

### ListenableSelector

A widget that rebuilds when a value selected from a `Listenable` changes.

```dart
ListenableSelector<MyScopeContent, int>(
  listenable: scope,
  selector: (scope) => scope.counter,
  builder: (context, scope, counter, child) {
    return Text('$counter');
  },
);
```

## Examples

Check out the `example` directory for more comprehensive examples:

-   [**minimal**](https://github.com/vi-k/scopo/tree/main/example/minimal): A simple counter app demonstrating basic usage.
-   [**scopo_demo**](https://github.com/vi-k/scopo/tree/main/example/scopo_demo): A more complex app with nested scopes, error simulation, and custom progress indicators.
