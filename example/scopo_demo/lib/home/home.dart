import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../app/app.dart';
import '../app/app_error.dart';
import '../app/theme_manager/theme_manager.dart';
import '../common/data/fake_services/some_bloc.dart';
import '../common/data/fake_services/some_controller.dart';
import '../common/presentation/animated_progress_indicator.dart';
import '../common/presentation/sized_tab_bar.dart';
import 'demos/data_access_demo/data_access_demo.dart';
import 'demos/scope_demo/scope_demo.dart';
import 'demos/scope_initializer_demo/scope_initializer_demo.dart';
import 'home_counter.dart';
import 'home_deps.dart';
import 'home_navigation_block.dart';

typedef HomeConsumer = ScopeConsumer<Home, HomeDependencies, HomeState>;

/// A child scope.
///
/// Initializes feature-specific dependencies like [SomeBloc] and
/// [SomeController].
final class Home extends Scope<Home, HomeDependencies, HomeState> {
  final ScopeInitFunction<double, HomeDependencies> _init;
  final bool isRoot;

  const Home({
    super.key,
    super.tag,
    required ScopeInitFunction<double, HomeDependencies> init,
    this.isRoot = true,
  }) : _init = init,
       super(pauseAfterInitialization: const Duration(milliseconds: 500));

  @override
  Stream<ScopeInitState<double, HomeDependencies>> init() => _init();

  /// Provides access the scope params, i.e. to the widget [Home].
  static Home paramsOf(BuildContext context, {bool listen = true}) =>
      Scope.paramsOf<Home, HomeDependencies, HomeState>(
        context,
        listen: listen,
      );

  static V selectParam<V extends Object?>(
    BuildContext context,
    V Function(Home widget) selector,
  ) => Scope.selectParam<Home, HomeDependencies, HomeState, V>(
    context,
    (widget) => selector(widget),
  );

  static HomeState? maybeOf(BuildContext context) =>
      Scope.maybeOf<Home, HomeDependencies, HomeState>(context);

  /// Provides access the [HomeState] and [HomeDependencies].
  static HomeState of(BuildContext context) =>
      Scope.of<Home, HomeDependencies, HomeState>(context);

  static V select<V extends Object?>(
    BuildContext context,
    V Function(HomeState state) selector,
  ) => Scope.select<Home, HomeDependencies, HomeState, V>(
    context,
    (state) => selector(state),
  );

  @override
  Widget buildOnInitializing(BuildContext context, Object? progress) =>
      _FakeContent(progress as double?);

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) => AppError(error, stackTrace);

  @override
  Widget wrapState(
    BuildContext context,
    HomeDependencies dependencies,
    Widget child,
  ) => NavigationNode(
    isRoot: isRoot,
    onPop: (context, result) async {
      await Home.of(context).close();
      return true;
    },
    child: child,
  );

  @override
  HomeState createState() => HomeState();
}

class HomeAppBar extends AppBar {
  HomeAppBar(BuildContext context, {super.key, bool withTabs = true})
    : super(
        title: Text('$Home'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: App.of(context).dependencies.connectivity,
            builder: (context, isConnected, _) {
              return Icon(
                color: isConnected ? null : Theme.of(context).colorScheme.error,
                isConnected
                    ? Icons.signal_cellular_4_bar
                    : Icons.signal_cellular_connected_no_internet_0_bar,
              );
            },
          ),
          IconButton(
            onPressed: () {
              ThemeManager.of(context, listen: false).toggleBrightness();
            },
            onLongPress: () {
              ThemeManager.of(context, listen: false).resetBrightness();
            },
            icon: Icon(switch (ThemeManager.select(
              context,
              (m) => m.brightness,
            )) {
              Brightness.dark => Icons.light_mode,
              Brightness.light => Icons.dark_mode,
            }),
          ),
        ],
        bottom:
            withTabs
                ? SizedTabBar(
                  height: 32,
                  isScrollable: true,
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.5),
                  tabs: const [
                    Tab(text: 'Data access'),
                    Tab(text: 'Async initialization'),
                    Tab(text: 'Scope'),
                    Tab(text: 'Other'),
                  ],
                )
                : null,
      );
}

/// The screen displays the progress of dependency initialization, mimicking
/// the [Home] screen.
class _FakeContent extends StatefulWidget {
  final double? progress;

  const _FakeContent(this.progress);

  @override
  State<_FakeContent> createState() => _FakeContentState();
}

class _FakeContentState extends State<_FakeContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(context, withTabs: false),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: AnimatedProgressIndicator(
            value: widget.progress,
            builder: (value) {
              return CircularProgressIndicator(value: value);
            },
          ),
        ),
      ),
    );
  }
}

mixin ChangeNotifierOnState<T extends StatefulWidget> on State<T>
    implements ChangeNotifier {
  final _innerNotifier = ChangeNotifier();

  @override
  bool get hasListeners => _innerNotifier.hasListeners;

  @override
  void dispose() {
    _innerNotifier.dispose();
    super.dispose();
  }

  @override
  void addListener(VoidCallback listener) =>
      _innerNotifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _innerNotifier.removeListener(listener);

  @override
  void notifyListeners() {
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    _innerNotifier.notifyListeners();
  }
}

/// [HomeState] is used to manage UI state and logic for [Home] scope.
final class HomeState extends ScopeState<Home, HomeDependencies, HomeState> {
  var _counter = 0;
  int get counter => _counter;

  @override
  void initState() {
    super.initState();

    // this.widget.;
    print(dependencies.someController);
  }

  void increment() {
    _counter++;
    notifyDependents();
  }

  void decrement() {
    _counter--;
    notifyDependents();
  }

  Future<void> openDialog(BuildContext context) => showAdaptiveDialog<void>(
    useRootNavigator: false,
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: 0.7),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(title: const Text('Dialog'), primary: false),
              const SizedBox(height: 20),
              const HomeCounter(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );

  void openBottomSheet(BuildContext context) {
    showBottomSheet(
      context: context,
      clipBehavior: Clip.antiAlias,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(title: const Text('Bottom sheet')),
              const SizedBox(height: 20),
              const HomeCounter(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  openBottomSheet(context);
                },
                child: const Text('more'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> openModalBottomSheet(BuildContext context) =>
      showModalBottomSheet(
        context: context,
        clipBehavior: Clip.antiAlias,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(title: const Text('Bottom sheet')),
                const SizedBox(height: 20),
                const HomeCounter(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: HomeAppBar(context),
            body: TabBarView(
              children: [
                const DataAccessDemo(),
                const ScopeInitializerDemo(),
                const ScopeDemo(),
                ListView(
                  children: [
                    _Timer(tag: Home.paramsOf(context).tag),
                    const Text('You have pushed this buttons many times:'),
                    const HomeCounter(),
                    const SizedBox(height: 20),
                    const SizedBox(height: 20),
                    const SizedBox(height: 20),
                    const HomeNavigationBlock(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('setState()'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Timer extends StatefulWidget {
  final String? tag;

  const _Timer({required this.tag});

  @override
  State<_Timer> createState() => _TimerState();
}

class _TimerState extends State<_Timer> {
  final _counter = ValueNotifier<int>(0);
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      _counter.value++;
      if (widget.tag case final tag?) {
        print('$tag: ${_counter.value}');
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _counter,
      builder: (context, value, _) {
        return Text('$value');
      },
    );
  }
}
