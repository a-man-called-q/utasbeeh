import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quran_core/quran_core.dart';

import '../settings/settings_store.dart';

/// Bookmarked ayat and where reading stopped, kept across restarts.
///
/// The last-read ayah is tracked on its own, so bookmarks stay the ayat the
/// reader chose.
class QuranStore extends ChangeNotifier {
  QuranStore(this._backend)
    : _bookmarks = {
        for (final raw in (_backend.read(_bookmarksKey) ?? '').split(','))
          ?parseAyahRef(raw),
      },
      _lastRead = parseAyahRef(_backend.read(_lastReadKey) ?? '');

  static const _bookmarksKey = 'quran.bookmarks';
  static const _lastReadKey = 'quran.lastRead';

  final SettingsBackend _backend;
  final Set<AyahRef> _bookmarks;
  AyahRef? _lastRead;

  AyahRef? get lastRead => _lastRead;

  bool isBookmarked(AyahRef ref) => _bookmarks.contains(ref);

  void toggleBookmark(AyahRef ref) {
    if (!_bookmarks.remove(ref)) _bookmarks.add(ref);
    unawaited(
      _backend.write(_bookmarksKey, _bookmarks.map(formatAyahRef).join(',')),
    );
    notifyListeners();
  }

  set lastRead(AyahRef? ref) {
    if (ref == null || ref == _lastRead) return;
    _lastRead = ref;
    unawaited(_backend.write(_lastReadKey, formatAyahRef(ref)));
    notifyListeners();
  }
}
