import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';
import 'package:scopo_demo/common/data/real_services/key_value_service.dart';

/// Demonstrates how to inject and manage global UI state within the scope.
class ThemeManager extends StatefulWidget {
  static const Color primarySeedColor = Colors.deepPurple;
  static const Color secondarySeedColor = Colors.lightBlue;
  static const Color tertiarySeedColor = Colors.lightGreen;
  static final String _modeKey = 'mode';

  late final ThemeMode initialMode;
  final Widget Function(BuildContext context) builder;
  final KeyValueService keyValueService;

  ThemeManager({
    super.key,
    required this.keyValueService,
    required this.builder,
  }) {
    final modeIndex = keyValueService.getInt(_modeKey) ?? 0;
    try {
      initialMode = ThemeMode.values[modeIndex];
    } on IndexError {
      initialMode = ThemeMode.system;
    }
  }

  static ThemeManagerState of(
    BuildContext context, {
    bool listen = true,
  }) =>
      maybeOf(
        context,
        listen: listen,
      ) ??
      (throw Exception('$ThemeManager not found in the context'));

  static ThemeManagerState? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) =>
      listen
          ? ScopeProvider.depend<ThemeManagerState>(context)
          : ScopeProvider.get<ThemeManagerState>(context);

  static ThemeData? _lightTheme;
  static ThemeData get lightTheme =>
      _lightTheme ??= _createTheme(Brightness.light);

  static ThemeData? _darkTheme;
  static ThemeData get darkTheme =>
      _darkTheme ??= _createTheme(Brightness.dark);

  static ThemeData _createTheme(Brightness brightness) {
    final blueColorScheme = ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: secondarySeedColor,
    );
    final greenColorScheme = ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: tertiarySeedColor,
    );
    var colorScheme = ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: primarySeedColor,
      secondary: blueColorScheme.primary,
      onSecondary: blueColorScheme.onPrimary,
      secondaryContainer: blueColorScheme.primaryContainer,
      onSecondaryContainer: blueColorScheme.onPrimaryContainer,
      tertiary: greenColorScheme.primary,
      onTertiary: greenColorScheme.onPrimary,
      tertiaryContainer: greenColorScheme.primaryContainer,
      onTertiaryContainer: greenColorScheme.onPrimaryContainer,
    );

    return ThemeData(
      colorScheme: colorScheme,
      canvasColor: colorScheme.surface,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.primaryContainer,
      ),
      tabBarTheme: TabBarThemeData(
        labelPadding: EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  @override
  State<ThemeManager> createState() => ThemeManagerState();

  @override
  String toStringShort() => '$ThemeManager';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(MessageProperty('primarySeedColor', '$primarySeedColor'))
      ..add(MessageProperty('secondarySeedColor', '$secondarySeedColor'))
      ..add(MessageProperty('tertiarySeedColor', '$tertiarySeedColor'))
      ..add(MessageProperty('initialMode', '$initialMode'));
  }
}

class ThemeManagerState extends State<ThemeManager> {
  late ThemeMode _mode = widget.initialMode;
  ThemeMode get mode => _mode;
  set mode(ThemeMode value) {
    if (_mode != value) {
      setState(() {
        widget.keyValueService.setInt(ThemeManager._modeKey, value.index);
        _mode = value;
      });
    }
  }

  Brightness get brightness => switch (mode) {
        ThemeMode.system => MediaQuery.platformBrightnessOf(context),
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
      };

  ThemeData get theme => switch (brightness) {
        Brightness.light => ThemeManager.lightTheme,
        Brightness.dark => ThemeManager.darkTheme,
      };

  ThemeData get lightTheme => ThemeManager.lightTheme;

  ThemeData get darkTheme => ThemeManager.darkTheme;

  void toggleBrightness() {
    setState(() {
      mode = switch (brightness) {
        Brightness.dark => ThemeMode.light,
        Brightness.light => ThemeMode.dark,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScopeProvider<ThemeManagerState>.value(
      value: this,
      builder: widget.builder,
    );
  }
}
