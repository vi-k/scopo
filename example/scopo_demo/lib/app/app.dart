import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../common/data/fake_services/analytics.dart';
import '../common/data/fake_services/connectivity.dart';
import '../common/data/fake_services/http_client.dart';
import 'app_deps.dart';
import 'app_error.dart';
import 'theme_manager.dart';

/// The root scope.
///
/// Initializes global dependencies like [HttpClient], [Connectivity], and
/// [Analytics].
final class App extends Scope<App, AppDeps, AppContent> {
  final ScopeOnInitCallback<double> _onInit;
  final Widget Function(BuildContext context) builder;

  const App({
    super.key,
    required ScopeInitFunction<double, AppDeps> super.init,
    required ScopeOnInitCallback<double> onInit,
    required this.builder,
  }) : _onInit = onInit;

  /// Provides access the scope params, i.e. to the widget [App].
  static App paramsOf(BuildContext context, {bool listen = true}) =>
      Scope.paramsOf<App, AppDeps, AppContent>(context, listen: listen);

  @override
  bool updateParamsShouldNotify(App oldWidget) => false;

  /// Provides access the scope content/dependencies.
  static AppContent of(BuildContext context) =>
      Scope.of<App, AppDeps, AppContent>(context);

  static AppContent? maybeOf(BuildContext context) =>
      Scope.maybeOf<App, AppDeps, AppContent>(context);

  Widget _app({
    ThemeMode mode = ThemeMode.system,
    ThemeData? light,
    ThemeData? dark,
    required Widget child,
  }) =>
      MaterialApp(
        title: 'Scope demo',
        themeMode: mode,
        theme: light ?? ThemeManager.lightTheme,
        darkTheme: dark ?? ThemeManager.darkTheme,
        debugShowCheckedModeBanner: false,
        home: child,
      );

  @override
  Widget onInit(Object? progress) => _app(child: _onInit(progress as double?));

  @override
  Widget onError(Object error, StackTrace stackTrace) =>
      _app(child: AppError(error, stackTrace));

  @override
  Widget wrapContent(AppDeps deps, Widget child) {
    return ThemeManager(
      keyValueService: deps.keyValueService('theme.'),
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
}

/// [AppContent] is used to manage UI state and logic for [App] scope.
final class AppContent extends ScopeContent<App, AppDeps, AppContent> {
  void updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => App.paramsOf(context).builder(context);
}

// sealed class AppState {}

// final class AppStateManager
//     extends ScopeStateManager<AppStateManager, AppState> {
//   final Widget child;

//   const AppStateManager({
//     super.key,
//     required super.initialState,
//     required this.child,
//   });

//   @override
//   Widget build(BuildContext context, AppState state) => child;
// }

// final class AppStateManager2 extends ScopeStateManagerBase<AppStateManager2,
//     AppStateManager2State, AppState> {
//   final Widget child;

//   const AppStateManager2({
//     super.key,
//     required super.initialState,
//     required this.child,
//   });

//   @override
//   Widget build(BuildContext context, AppState state) => child;

//   @override
//   State<StatefulWidget> createState() => AppStateManager2State();
// }

// final class AppStateManager2State extends ScopeStateManagerStateBase<
//     AppStateManager2, AppStateManager2State, AppState> {}
