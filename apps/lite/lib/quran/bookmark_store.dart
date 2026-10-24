import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quran_core/quran_core.dart';

import '../storage.dart';

/// Bookmarked ayat, newest first, kept across restarts. In Lite they are
/// the whole point of the Qur'an tab, so their order is kept too.
class BookmarkStore extends ChangeNotifier {
  BookmarkStore(this._storage)
    // A set literal keeps the stored order and drops repeats.
    : _bookmarks = {
        for (final raw in (_storage.read(_key) ?? '').split(','))
          ?parseAyahRef(raw),
      }.toList();

  static const _key = 'quran.bookmarks';

  final Storage _storage;
  final List<AyahRef> _bookmarks;

  List<AyahRef> get bookmarks => List.unmodifiable(_bookmarks);

  bool isBookmarked(AyahRef ref) => _bookmarks.contains(ref);

  void toggle(AyahRef ref) => isBookmarked(ref) ? remove(ref) : insert(ref);

  /// Adds [ref] at [index], newest first by default. Undoing a removal puts
  /// it back where it was.
  void insert(AyahRef ref, [int index = 0]) {
    if (isBookmarked(ref)) return;
    _bookmarks.insert(index.clamp(0, _bookmarks.length), ref);
    _save();
  }

  /// Removes [ref] and returns where it was, or -1 if it was not there.
  int remove(AyahRef ref) {
    final index = _bookmarks.indexOf(ref);
    if (index < 0) return index;
    _bookmarks.removeAt(index);
    _save();
    return index;
  }

  void _save() {
    unawaited(_storage.write(_key, _bookmarks.map(formatAyahRef).join(',')));
    notifyListeners();
  }
}
