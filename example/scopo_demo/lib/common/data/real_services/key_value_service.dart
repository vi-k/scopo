import 'package:shared_preferences/shared_preferences.dart';

final class KeyValueService {
  final SharedPreferences sharedPreferences;
  final String prefix;

  KeyValueService({required this.sharedPreferences, required this.prefix});

  String _prefixedKey(String key) => '$prefix$key';

  Object? get(String key) => sharedPreferences.get(_prefixedKey(key));

  int? getInt(String key) => sharedPreferences.getInt(_prefixedKey(key));

  bool? getBool(String key) => sharedPreferences.getBool(_prefixedKey(key));

  Future<void> setBool(String key, bool value) =>
      sharedPreferences.setBool(_prefixedKey(key), value);

  Future<void> setInt(String key, int value) =>
      sharedPreferences.setInt(_prefixedKey(key), value);

  double? getDouble(String key) =>
      sharedPreferences.getDouble(_prefixedKey(key));

  Future<void> setDouble(String key, double value) =>
      sharedPreferences.setDouble(_prefixedKey(key), value);

  String? getString(String key) =>
      sharedPreferences.getString(_prefixedKey(key));

  Future<void> setString(String key, String value) =>
      sharedPreferences.setString(_prefixedKey(key), value);

  List<String>? getStringList(String key) =>
      sharedPreferences.getStringList(_prefixedKey(key));

  Future<void> setStringList(String key, List<String> value) =>
      sharedPreferences.setStringList(_prefixedKey(key), value);

  bool containsKey(String key) =>
      sharedPreferences.containsKey(_prefixedKey(key));

  Future<void> remove(String key) =>
      sharedPreferences.remove(_prefixedKey(key));

  Set<String> getKeys() => {
    for (final key in sharedPreferences.getKeys())
      if (key.startsWith(prefix)) key.substring(prefix.length),
  };

  Future<void> clear() async {
    for (final key in sharedPreferences.getKeys()) {
      if (key.startsWith(prefix)) {
        await sharedPreferences.remove(key);
      }
    }
  }

  Future<void> reload() => sharedPreferences.reload();
}
