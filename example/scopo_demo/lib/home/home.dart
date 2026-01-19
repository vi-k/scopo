import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../app/app_error.dart';
import '../app/theme_manager/theme_manager.dart';
import '../common/data/fake_services/fake_bloc.dart';
import '../common/data/fake_services/fake_controller.dart';
import '../common/presentation/animated_progress_indicator.dart';
import '../common/presentation/sized_tab_bar.dart';
import 'demos/a_scope_widget/scope_widget_demo.dart';
import 'demos/b_scope_model/scope_model_demo.dart';
import 'demos/c_scope_notifier/scope_notifier_demo.dart';
import 'demos/data_access_demo/data_access_demo.dart';
import 'demos/scope_demo/scope_demo.dart';
import 'demos/scope_initializer_demo/scope_initializer_demo.dart';
import 'home_counter.dart';
import 'home_dependencies.dart';
import 'home_navigation_block.dart';

typedef HomeConsumer = ScopeConsumer<Home, HomeDependencies, HomeState>;

const _tabs = <(String, Widget)>[
  ('Common', _Common()),
  ('ScopeWidget', ScopeWidgetDemo()),
  ('ScopeModel', ScopeModelDemo()),
  ('ScopeNotifier', ScopeNotifierDemo()),
  ('Data access (old)', DataAccessDemo()),
  ('Async initialization', ScopeInitializerDemo()),
  ('Scope', ScopeDemo()),
];

/// A child scope.
///
/// Initializes feature-specific dependencies like [FakeBloc] and
/// [FakeController].
final class Home extends Scope<Home, HomeDependencies, HomeState> {
  final ScopeInitFunction<double, HomeDependencies> _init;
  final bool isRoot;

  const Home({
    super.key,
    super.tag,
    required ScopeInitFunction<double, HomeDependencies> init,
    this.isRoot = true,
  })  : _init = init,
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
  ) =>
      Scope.selectParam<Home, HomeDependencies, HomeState, V>(
        context,
        (widget) => selector(widget),
      );

  /// Provides access the [HomeState] and [HomeDependencies].
  static HomeState of(BuildContext context) =>
      Scope.of<Home, HomeDependencies, HomeState>(context);

  static V select<V extends Object?>(
    BuildContext context,
    V Function(HomeState state) selector,
  ) =>
      Scope.select<Home, HomeDependencies, HomeState, V>(
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
  ) =>
      AppError(error, stackTrace);

  @override
  Widget wrapState(
    BuildContext context,
    HomeDependencies dependencies,
    Widget child,
  ) =>
      NavigationNode(
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
            IconButton(
              onPressed: () {
                ThemeManager.of(context, listen: false).toggleBrightness();
              },
              onLongPress: () {
                ThemeManager.of(context, listen: false).resetBrightness();
              },
              icon: Icon(
                switch (ThemeManager.select(
                  context,
                  (m) => m.brightness,
                )) {
                  Brightness.dark => Icons.light_mode,
                  Brightness.light => Icons.dark_mode,
                },
              ),
            ),
          ],
          bottom: withTabs
              ? SizedTabBar(
                  height: 32,
                  isScrollable: true,
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.5),
                  tabs: _tabs.map((e) => Tab(text: e.$1)).toList(),
                )
              : null,
        );
}

/// The screen displays the progress of dependency initialization, mimicking
/// the [Home] screen.
class _FakeContent extends StatelessWidget {
  final double? progress;

  const _FakeContent(this.progress);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(context, withTabs: false),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: AnimatedProgressIndicator(
            value: progress,
            builder: (value) {
              return CircularProgressIndicator(value: value);
            },
          ),
        ),
      ),
    );
  }
}

/// [HomeState] is used to manage UI state and logic for [Home] scope.
final class HomeState extends ScopeState<Home, HomeDependencies, HomeState> {
  var _counter = 0;
  int get counter => _counter;

  @override
  void initState() {
    super.initState();

    // Пример использования
    // ignore: unused_local_variable
    final controller = dependencies.controller;
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
          length: _tabs.length,
          child: Scaffold(
            appBar: HomeAppBar(context),
            body: TabBarView(children: _tabs.map((e) => e.$2).toList()),
          ),
        );
      },
    );
  }
}

class _Common extends StatelessWidget {
  const _Common();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: [
        const Center(child: Text('You have pushed this buttons many times:')),
        const Center(child: HomeCounter()),
        const SizedBox(height: 20),
        if (!Home.paramsOf(context).isRoot) ...[
          const _LiveIndicator(),
          const SizedBox(height: 40),
        ],
        const HomeNavigationBlock(),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.flip(
            flipX: true,
            child: const SizedBox(
              width: 50,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          ),
          const Text('  Live indicator  '),
          const SizedBox(
            width: 50,
            child: LinearProgressIndicator(minHeight: 2),
          ),
        ],
      ),
    );
  }
}
