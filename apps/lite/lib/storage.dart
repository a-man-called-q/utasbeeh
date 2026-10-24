import 'package:shared_preferences/shared_preferences.dart';

/// Where the count and bookmarks are kept: SharedPreferences in the app, a
/// map in tests.
abstract interface class Storage {
  String? read(String key);
  Future<void> write(String key, String value);
}

class SharedPrefsStorage implements Storage {
  SharedPrefsStorage._(this._prefs);

  static Future<SharedPrefsStorage> open() async => SharedPrefsStorage._(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    ),
  );

  final SharedPreferencesWithCache _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
}

/// For tests.
class InMemoryStorage implements Storage {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
