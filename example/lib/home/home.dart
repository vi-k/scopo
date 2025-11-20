import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../app/app.dart';
import '../app/app_error.dart';
import '../app/theme_manager.dart';
import '../common/animated_progress_indicator.dart';
import 'home_counter.dart';
import 'home_deps.dart';
import 'home_navigation_block.dart';

typedef HomeConsumer = ScopeConsumer<Home, HomeDeps, HomeContent>;

final class Home extends Scope<Home, HomeDeps, HomeContent> {
  const Home({
    super.key,
    required ScopeInitFunction<double, HomeDeps> super.init,
  });

  static HomeContent of(BuildContext context) =>
      Scope.of<Home, HomeDeps, HomeContent>(context);

  @override
  bool updateParamsShouldNotify(Home oldWidget) => false;

  @override
  Widget onInit(Object? progress) => _FakeContent(progress as double?);

  @override
  Widget onError(Object error, StackTrace stackTrace) =>
      AppError(error, stackTrace);

  @override
  Widget wrapContent(HomeDeps deps, Widget child) =>
      NavigationNode(isRoot: true, child: child);

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
            builder:
                (context, isConnected, _) => Icon(
                  color:
                      isConnected ? null : Theme.of(context).colorScheme.error,
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

final class HomeContent extends ScopeContent<Home, HomeDeps, HomeContent>
    with ChangeNotifier {
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
          ).colorScheme.surface.withValues(alpha: 0.8),
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
    return Scaffold(
      appBar: HomeAppBar(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('You have pushed this buttons many times:'),
            HomeCounter(),
            SizedBox(height: 20),
            HomeNavigationBlock(),
          ],
        ),
      ),
    );
  }
}
