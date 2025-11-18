import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import 'app_deps.dart';
import 'app_error.dart';
import 'theme_manager.dart';

final class App extends Scope<App, double, AppDeps, AppContent> {
  final ScopeOnInitCallback<double> _onInit;
  final Widget Function(BuildContext context) builder;

  const App({
    super.key,
    required super.init,
    required ScopeOnInitCallback<double> onInit,
    required this.builder,
  }) : _onInit = onInit,
       super(initialStep: 0);

  static App paramsOf(BuildContext context, {bool listen = true}) =>
      Scope.paramsOf<App, double, AppDeps, AppContent>(context, listen: listen);

  static AppContent of(BuildContext context) =>
      Scope.of<App, double, AppDeps, AppContent>(context);

  static AppContent? maybeOf(BuildContext context) =>
      Scope.maybeOf<App, double, AppDeps, AppContent>(context);

  Widget _app({
    ThemeMode mode = ThemeMode.system,
    ThemeData? light,
    ThemeData? dark,
    required Widget child,
  }) => MaterialApp(
    title: 'Scope demo',
    themeMode: mode,
    theme: light ?? ThemeManager.defaultLightTheme,
    darkTheme: dark ?? ThemeManager.defaultDarkTheme,
    debugShowCheckedModeBanner: false,
    home: child,
  );

  @override
  Widget onInit(double progress) => _app(child: _onInit(progress));

  @override
  Widget onError(Object error, StackTrace stackTrace) =>
      _app(child: AppError(error, stackTrace));

  @override
  Widget wrapContent(AppDeps deps, Widget child) {
    return ThemeManager(
      builder: (context) {
        final themeManager = ThemeManager.of(context);

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Banner(
            message: 'scopo demo',
            location: BannerLocation.bottomEnd,
            color: themeManager.theme.colorScheme.primary,
            textStyle: TextStyle(
              color: themeManager.theme.colorScheme.onPrimary,
              fontSize: 9,
              fontWeight: FontWeight.normal,
              height: 1.0,
            ),
            child: _app(
              mode: themeManager.mode,
              light: themeManager.lightTheme,
              dark: themeManager.darkTheme,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  AppContent createContent() => AppContent();

  @override
  bool updateParamsShouldNotify(App oldWidget) => false;
}

final class AppContent extends ScopeContent<App, double, AppDeps, AppContent> {
  @override
  void initState() {
    super.initState();

    deps.connectivity.addListener(_changeThemeActive);
  }

  @override
  void dispose() {
    deps.connectivity.removeListener(_changeThemeActive);

    super.dispose();
  }

  void _changeThemeActive() {
    ThemeManager.of(context, listen: false).active = deps.connectivity.value;
  }

  @override
  Widget build(BuildContext context) => App.paramsOf(context).builder(context);
}
