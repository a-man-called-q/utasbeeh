import 'dart:convert';

import 'package:dzikir_core/dzikir_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unfinished progress and last completion per collection.
///
/// Reads are synchronous so lists render without loading states; writes are
/// fire-and-forget so counting never waits on storage.
abstract interface class DzikirProgressStore {
  DzikirProgress? progressFor(String collectionId);
  Future<void> saveProgress(DzikirProgress progress);
  Future<void> clearProgress(String collectionId);

  DateTime? completedAt(String collectionId);
  Future<void> markCompleted(String collectionId, DateTime at);
}

class SharedPrefsDzikirProgressStore implements DzikirProgressStore {
  SharedPrefsDzikirProgressStore._(this._prefs);

  static Future<SharedPrefsDzikirProgressStore> open() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    return SharedPrefsDzikirProgressStore._(prefs);
  }

  final SharedPreferencesWithCache _prefs;

  static String _progressKey(String id) => 'dzikir.progress.$id';
  static String _completedKey(String id) => 'dzikir.completed.$id';

  @override
  DzikirProgress? progressFor(String collectionId) {
    final raw = _prefs.getString(_progressKey(collectionId));
    if (raw == null) return null;
    try {
      return DzikirProgress.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> saveProgress(DzikirProgress progress) => _prefs.setString(
    _progressKey(progress.collectionId),
    jsonEncode(progress.toJson()),
  );

  @override
  Future<void> clearProgress(String collectionId) =>
      _prefs.remove(_progressKey(collectionId));

  @override
  DateTime? completedAt(String collectionId) =>
      DateTime.tryParse(_prefs.getString(_completedKey(collectionId)) ?? '');

  @override
  Future<void> markCompleted(String collectionId, DateTime at) =>
      _prefs.setString(_completedKey(collectionId), at.toIso8601String());
}

/// For tests and previews.
class InMemoryDzikirProgressStore implements DzikirProgressStore {
  final progress = <String, DzikirProgress>{};
  final completed = <String, DateTime>{};

  @override
  DzikirProgress? progressFor(String collectionId) => progress[collectionId];

  @override
  Future<void> saveProgress(DzikirProgress value) async =>
      progress[value.collectionId] = value;

  @override
  Future<void> clearProgress(String collectionId) async =>
      progress.remove(collectionId);

  @override
  DateTime? completedAt(String collectionId) => completed[collectionId];

  @override
  Future<void> markCompleted(String collectionId, DateTime at) async =>
      completed[collectionId] = at;
}
