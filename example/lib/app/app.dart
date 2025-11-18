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

  @override
  Widget onInit(double progress) => _onInit(progress);

  @override
  Widget onError(Object error, StackTrace stackTrace) =>
      AppError(error, stackTrace);

  @override
  AppContent createContent() => AppContent();

  @override
  Widget wrap(ScopeDepsState<double, AppDeps> state, Widget child) {
    Widget app({
      required ThemeMode mode,
      required ThemeData light,
      required ThemeData dark,
    }) => MaterialApp(
      title: 'Scope demo',
      themeMode: mode,
      theme: light,
      darkTheme: dark,
      debugShowCheckedModeBanner: false,
      home: child,
    );

    return switch (state) {
      ScopeProgress() || ScopeError() => app(
        mode: ThemeMode.system,
        light: ThemeManager.defaultLightTheme,
        dark: ThemeManager.defaultDarkTheme,
      ),
      ScopeReady() => ThemeManager(
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
              child: app(
                mode: themeManager.mode,
                light: themeManager.lightTheme,
                dark: themeManager.darkTheme,
              ),
            ),
          );
        },
      ),
    };
  }

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
