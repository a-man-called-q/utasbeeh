import 'dart:async';

import 'package:flutter/foundation.dart';

import '../settings/settings_store.dart';

/// An ayah's address, e.g. 2:255.
typedef AyahRef = ({int surah, int ayah});

String _key(AyahRef ref) => '${ref.surah}:${ref.ayah}';

AyahRef? _parse(String raw) {
  final parts = raw.split(':');
  if (parts.length != 2) return null;
  final surah = int.tryParse(parts[0]);
  final ayah = int.tryParse(parts[1]);
  return surah == null || ayah == null ? null : (surah: surah, ayah: ayah);
}

/// Bookmarked ayat and where reading stopped, kept across restarts.
///
/// The last-read ayah is tracked on its own, so bookmarks stay the ayat the
/// reader chose.
class QuranStore extends ChangeNotifier {
  QuranStore(this._backend)
    : _bookmarks = {
        for (final raw in (_backend.read(_bookmarksKey) ?? '').split(','))
          ?_parse(raw),
      },
      _lastRead = _parse(_backend.read(_lastReadKey) ?? '');

  static const _bookmarksKey = 'quran.bookmarks';
  static const _lastReadKey = 'quran.lastRead';

  final SettingsBackend _backend;
  final Set<AyahRef> _bookmarks;
  AyahRef? _lastRead;

  AyahRef? get lastRead => _lastRead;

  bool isBookmarked(AyahRef ref) => _bookmarks.contains(ref);

  void toggleBookmark(AyahRef ref) {
    if (!_bookmarks.remove(ref)) _bookmarks.add(ref);
    unawaited(_backend.write(_bookmarksKey, _bookmarks.map(_key).join(',')));
    notifyListeners();
  }

  set lastRead(AyahRef? ref) {
    if (ref == null || ref == _lastRead) return;
    _lastRead = ref;
    unawaited(_backend.write(_lastReadKey, _key(ref)));
    notifyListeners();
  }
}
