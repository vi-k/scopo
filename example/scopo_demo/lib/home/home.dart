import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../app/app.dart';
import '../app/app_error.dart';
import '../app/theme_manager.dart';
import '../common/animated_progress_indicator.dart';
import '../fake_dependencies/some_bloc.dart';
import '../fake_dependencies/some_controller.dart';
import 'home_counter.dart';
import 'home_deps.dart';
import 'home_navigation_block.dart';

typedef HomeConsumer = ScopeConsumer<Home, HomeDeps, HomeContent>;

/// A child scope.
///
/// Initializes feature-specific dependencies like [SomeBloc] and
/// [SomeController].
final class Home extends Scope<Home, HomeDeps, HomeContent> {
  final bool isRoot;

  const Home({
    super.key,
    super.tag,
    required ScopeInitFunction<double, HomeDeps> super.init,
    this.isRoot = true,
  });

  /// Provides access the scope params, i.e. to the widget [Home].
  static Home paramsOf(BuildContext context, {bool listen = true}) =>
      Scope.paramsOf<Home, HomeDeps, HomeContent>(context, listen: listen);

  @override
  bool updateParamsShouldNotify(Home oldWidget) => false;

  /// Provides access the [HomeContent] and [HomeDeps].
  static HomeContent of(BuildContext context) =>
      Scope.of<Home, HomeDeps, HomeContent>(context);

  @override
  Widget onInit(Object? progress) => _FakeContent(progress as double?);

  @override
  Widget onError(Object error, StackTrace stackTrace) =>
      AppError(error, stackTrace);

  @override
  Widget wrapContent(HomeDeps deps, Widget child) => NavigationNode(
        isRoot: isRoot,
        onPop: (context, result) async {
          await Home.of(context).close();
          return true;
        },
        child: child,
      );

  @override
  HomeContent createContent() => HomeContent();
}

class HomeAppBar extends AppBar {
  HomeAppBar(BuildContext context, {super.key})
      : super(
          title: Text('$Home'),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: App.of(context).deps.connectivity,
              builder: (context, isConnected, _) => Icon(
                color: isConnected ? null : Theme.of(context).colorScheme.error,
                isConnected
                    ? Icons.signal_cellular_4_bar
                    : Icons.signal_cellular_connected_no_internet_0_bar,
              ),
            ),
            IconButton(
              onPressed: () {
                ThemeManager.of(context, listen: false).toggleBrightness();
              },
              onLongPress: () {
                ThemeManager.of(context, listen: false).mode = ThemeMode.system;
              },
              icon: Icon(switch (ThemeManager.of(context).brightness) {
                Brightness.dark => Icons.light_mode,
                Brightness.light => Icons.dark_mode,
              }),
            ),
          ],
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
      appBar: HomeAppBar(context),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Center(
          child: AnimatedProgressIndicator(
            value: widget.progress,
            builder: (value) => CircularProgressIndicator(value: value),
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

/// [HomeContent] is used to manage UI state and logic for [Home] scope.
final class HomeContent extends ScopeContent<Home, HomeDeps, HomeContent> {
  var _counter = 0;
  int get counter => _counter;

  void increment() {
    _counter++;
    notifyListeners();
  }

  void decrement() {
    _counter--;
    notifyListeners();
  }

  void openDialog(BuildContext context) {
    showAdaptiveDialog(
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
                AppBar(title: Text('Dialog'), primary: false),
                SizedBox(height: 20),
                HomeCounter(),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void openBottomSheet(BuildContext context) {
    showBottomSheet(
      context: context,
      clipBehavior: Clip.antiAlias,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(title: Text('Bottom sheet')),
              SizedBox(height: 20),
              HomeCounter(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  openBottomSheet(context);
                },
                child: Text('more'),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void openModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      clipBehavior: Clip.antiAlias,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(title: Text('Bottom sheet')),
              SizedBox(height: 20),
              HomeCounter(),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Scaffold(
          appBar: HomeAppBar(context),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('You have pushed this buttons many times:'),
                HomeCounter(),
                SizedBox(height: 20),
                HomeNavigationBlock(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('setState()'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
