import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../storage.dart';

/// One running count, kept across restarts. No targets or phrases: the
/// reader keeps those in mind.
class TasbihStore extends ChangeNotifier {
  TasbihStore(this._storage)
    : _count = math.max(0, int.tryParse(_storage.read(_key) ?? '') ?? 0);

  static const _key = 'tasbih.count';

  final Storage _storage;
  int _count;

  int get count => _count;

  void increment() => _set(_count + 1);

  /// Takes back one count; never below zero.
  void decrement() {
    if (_count > 0) _set(_count - 1);
  }

  void reset() => _set(0);

  void _set(int value) {
    if (value == _count) return;
    _count = value;
    unawaited(_storage.write(_key, '$value'));
    notifyListeners();
  }
}
