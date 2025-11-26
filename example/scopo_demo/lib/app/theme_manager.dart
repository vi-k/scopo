import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Demonstrates how to inject and manage global UI state within the scope.
class ThemeManager extends StatefulWidget {
  static Color seedColor = Colors.deepPurple;
  static DynamicSchemeVariant activeSchemeVariant =
      DynamicSchemeVariant.tonalSpot;
  static DynamicSchemeVariant inactiveSchemeVariant =
      DynamicSchemeVariant.neutral;

  final ThemeMode initialMode;
  final bool initialActive;
  final Widget Function(BuildContext context) builder;

  const ThemeManager({
    super.key,
    this.initialMode = ThemeMode.system,
    this.initialActive = true,
    required this.builder,
  });

  static ThemeManagerState of(BuildContext context, {bool listen = true}) =>
      maybeOf(context, listen: listen) ??
      (throw Exception('$ThemeManager not found in the context'));

  static ThemeManagerState? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) =>
      _ThemeManagerScope.maybeOf(context, listen: listen)?.manager;

  static ThemeData? _defaultLightTheme;
  static ThemeData get defaultLightTheme =>
      _defaultLightTheme ??= _createTheme(Brightness.light, true);

  static ThemeData? _defaultDartTheme;
  static ThemeData get defaultDarkTheme =>
      _defaultDartTheme ??= _createTheme(Brightness.light, true);

  static ThemeData _createTheme(Brightness brightness, bool active) {
    final colorScheme = ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: seedColor,
      dynamicSchemeVariant:
          active ? activeSchemeVariant : inactiveSchemeVariant,
    );
    return ThemeData(
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor:
            active ? colorScheme.primary : colorScheme.inversePrimary,
        foregroundColor: active ? colorScheme.onPrimary : colorScheme.onSurface,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.primaryContainer,
      ),
    );
  }

  @override
  State<ThemeManager> createState() => ThemeManagerState();

  @override
  String toStringShort() => '$ThemeManager';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(MessageProperty('seedColor', '$seedColor'))
      ..add(MessageProperty('initialMode', '$initialMode'))
      ..add(MessageProperty('initialActive', '$initialActive'));
    super.debugFillProperties(properties);
  }
}

class ThemeManagerState extends State<ThemeManager> {
  late final Map<(Brightness, bool), ThemeData> _themes;

  late ThemeMode _mode = widget.initialMode;
  ThemeMode get mode => _mode;
  set mode(ThemeMode value) {
    if (_mode != value) {
      setState(() {
        _mode = value;
      });
    }
  }

  late bool _active = widget.initialActive;
  bool get active => _active;
  set active(bool value) {
    if (_active != value) {
      setState(() {
        _active = value;
      });
    }
  }

  Brightness get brightness => switch (mode) {
        ThemeMode.system => MediaQuery.platformBrightnessOf(context),
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
      };

  ThemeData get theme => _themes[(brightness, _active)]!;

  ThemeData get lightTheme => _themes[(Brightness.light, _active)]!;

  ThemeData get darkTheme => _themes[(Brightness.dark, _active)]!;

  void toggleBrightness() {
    setState(() {
      mode = switch (brightness) {
        Brightness.dark => ThemeMode.light,
        Brightness.light => ThemeMode.dark,
      };
    });
  }

  @override
  void initState() {
    super.initState();

    _themes = {
      for (final brightness in Brightness.values)
        for (final active in [true, false])
          (brightness, active): ThemeManager._createTheme(brightness, active),
    };
  }

  @override
  Widget build(BuildContext context) {
    return _ThemeManagerScope(
      manager: this,
      child: Builder(
        builder: (context) {
          return widget.builder(context);
        },
      ),
    );
  }
}

class _ThemeManagerScope extends InheritedWidget {
  final ThemeManagerState manager;
  final ThemeMode mode;
  final bool active;

  _ThemeManagerScope({required this.manager, required super.child})
      : mode = manager._mode,
        active = manager._active;

  static _ThemeManagerScope? maybeOf(
    BuildContext context, {
    required bool listen,
  }) =>
      listen
          ? context.dependOnInheritedWidgetOfExactType<_ThemeManagerScope>()
          : context.getInheritedWidgetOfExactType<_ThemeManagerScope>();

  @override
  bool updateShouldNotify(_ThemeManagerScope oldWidget) =>
      mode != oldWidget.mode || active != oldWidget.active;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(MessageProperty('mode', '$mode'))
      ..add(MessageProperty('active', '$active'));
    super.debugFillProperties(properties);
  }
}
