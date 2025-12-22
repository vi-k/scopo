part of 'theme_manager.dart';

abstract interface class ThemeModel implements Listenable {
  ThemeMode get mode;

  Brightness get brightness;

  ThemeData get theme;

  ThemeData get lightTheme;

  ThemeData get darkTheme;

  void toggleBrightness();

  void resetBrightness();
}

final class _ThemeModelNotifier extends ChangeNotifier implements ThemeModel {
  static const String _modeKey = 'mode';

  final KeyValueService keyValueService;

  Brightness Function()? _systemBrightness;

  _ThemeModelNotifier({
    required this.keyValueService,
    required Brightness Function() systemBrightness,
  }) : _mode = _initialMode(keyValueService),
       _systemBrightness = systemBrightness;

  static ThemeMode _initialMode(KeyValueService keyValueService) {
    final modeIndex = keyValueService.getInt(_modeKey) ?? 0;
    try {
      return ThemeMode.values[modeIndex];
      // ignore: avoid_catching_errors
    } on IndexError {
      return ThemeMode.system;
    }
  }

  @override
  ThemeMode get mode => _mode;
  ThemeMode _mode;
  set mode(ThemeMode value) {
    if (_mode != value) {
      // ignore: discarded_futures
      keyValueService.setInt(_modeKey, value.index);
      _mode = value;
      notifyListeners();
    }
  }

  @override
  Brightness get brightness => switch (_mode) {
    ThemeMode.system => _systemBrightness!(),
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
  };

  @override
  ThemeData get theme => switch (brightness) {
    Brightness.light => lightTheme,
    Brightness.dark => darkTheme,
  };

  @override
  ThemeData get lightTheme => StaticThemes.lightTheme;

  @override
  ThemeData get darkTheme => StaticThemes.darkTheme;

  @override
  void dispose() {
    _systemBrightness = null;
    super.dispose();
  }

  @override
  void toggleBrightness() {
    mode = switch (brightness) {
      Brightness.dark => ThemeMode.light,
      Brightness.light => ThemeMode.dark,
    };
  }

  @override
  void resetBrightness() {
    mode = ThemeMode.system;
  }
}
