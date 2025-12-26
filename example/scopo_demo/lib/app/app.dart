import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../common/data/fake_services/analytics.dart';
import '../common/data/fake_services/connectivity.dart';
import '../common/data/fake_services/http_client.dart';
import 'app_deps.dart';
import 'app_error.dart';
import 'theme_manager/theme_manager.dart';

/// The root scope.
///
/// Initializes global dependencies like [HttpClient], [Connectivity], and
/// [Analytics].
final class App extends Scope<App, AppDependencies, AppState> {
  final ScopeInitFunction<double, AppDependencies> _init;
  final ScopeOnInitCallback<double> _onInit;
  final Widget Function(BuildContext context) builder;

  const App({
    super.key,
    required ScopeInitFunction<double, AppDependencies> init,
    required ScopeOnInitCallback<double> initBuilder,
    required this.builder,
  }) : _init = init,
       _onInit = initBuilder,
       super(pauseAfterInitialization: const Duration(milliseconds: 500));

  @override
  Stream<ScopeInitState<double, AppDependencies>> init() => _init();

  /// Provides access the scope params, i.e. to the widget [App].
  static App paramsOf(BuildContext context, {bool listen = true}) =>
      Scope.paramsOf<App, AppDependencies, AppState>(context, listen: listen);

  static V selectParam<V extends Object?>(
    BuildContext context,
    V Function(App widget) selector,
  ) => Scope.selectParam<App, AppDependencies, AppState, V>(
    context,
    (widget) => selector(widget),
  );

  static AppState? maybeOf(BuildContext context) =>
      Scope.maybeOf<App, AppDependencies, AppState>(context);

  /// Provides access the scope state.
  static AppState of(BuildContext context) =>
      Scope.of<App, AppDependencies, AppState>(context);

  static V select<V extends Object?>(
    BuildContext context,
    V Function(AppState state) selector,
  ) => Scope.select<App, AppDependencies, AppState, V>(
    context,
    (state) => selector(state),
  );

  Widget _app({
    ThemeMode mode = ThemeMode.system,
    ThemeData? light,
    ThemeData? dark,
    required Widget child,
  }) => MaterialApp(
    title: 'Scope demo',
    themeMode: mode,
    theme: light ?? StaticThemes.lightTheme,
    darkTheme: dark ?? StaticThemes.darkTheme,
    debugShowCheckedModeBanner: false,
    home: child,
  );

  @override
  Widget buildOnInitializing(BuildContext context, Object? progress) =>
      _app(child: _onInit(context, progress as double?));

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) => _app(child: AppError(error, stackTrace));

  @override
  Widget wrapState(
    BuildContext context,
    AppDependencies dependencies,
    Widget child,
  ) => ThemeManager(
    keyValueService: dependencies.keyValueService('theme.'),
    builder: (context) {
      final themeModel = ThemeManager.of(context);

      return Directionality(
        textDirection: TextDirection.ltr,
        child: Banner(
          message: 'scopo',
          location: BannerLocation.bottomEnd,
          color: themeModel.theme.colorScheme.primary,
          textStyle: TextStyle(
            color: themeModel.theme.colorScheme.onPrimary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
          shadow: const BoxShadow(color: Colors.transparent),
          child: _app(
            mode: themeModel.mode,
            light: themeModel.lightTheme,
            dark: themeModel.darkTheme,
            child: child,
          ),
        ),
      );
    },
  );

  @override
  AppState createState() => AppState();
}

/// [AppState] is used to manage UI state and logic for [App] scope.
final class AppState extends ScopeState<App, AppDependencies, AppState> {
  @override
  Widget build(BuildContext context) {
    return App.paramsOf(context).builder(context);
  }
}
