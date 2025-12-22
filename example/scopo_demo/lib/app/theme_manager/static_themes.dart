part of 'theme_manager.dart';

// ignore: avoid_classes_with_only_static_members
abstract interface class StaticThemes {
  static const Color primarySeedColor = Colors.deepPurple;
  static const Color secondarySeedColor = Colors.lightBlue;
  static const Color tertiarySeedColor = Colors.lightGreen;

  static ThemeData? _lightTheme;
  static ThemeData get lightTheme =>
      _lightTheme ??= _themeFor(Brightness.light);

  static ThemeData? _darkTheme;
  static ThemeData get darkTheme => _darkTheme ??= _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) {
    final secondaryColorScheme = ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: secondarySeedColor,
    );
    final tertiaryColorScheme = ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: tertiarySeedColor,
    );
    final colorScheme = ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: primarySeedColor,
      secondary: secondaryColorScheme.primary,
      onSecondary: secondaryColorScheme.onPrimary,
      secondaryContainer: secondaryColorScheme.primaryContainer,
      onSecondaryContainer: secondaryColorScheme.onPrimaryContainer,
      tertiary: tertiaryColorScheme.primary,
      onTertiary: tertiaryColorScheme.onPrimary,
      tertiaryContainer: tertiaryColorScheme.primaryContainer,
      onTertiaryContainer: tertiaryColorScheme.onPrimaryContainer,
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
      tabBarTheme: const TabBarThemeData(
        labelPadding: EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
