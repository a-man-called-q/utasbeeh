import 'dart:async';

import 'package:dzikir_core/dzikir_core.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'dzikir_progress_store.dart';

/// Everything the dzikir screens need from outside, bundled so tests can
/// swap storage, haptics, wakelock and the clock.
class DzikirServices {
  const DzikirServices({
    required this.library,
    required this.store,
    this.feedback = const HapticDzikirFeedback(),
    this.keepAwake = _wakelock,
    this.clock = DateTime.now,
  });

  static const contentAsset = 'packages/dzikir_core/content/dzikir.json';

  static Future<DzikirLibrary> loadLibrary(AssetBundle bundle) async =>
      DzikirLibrary.parse(await bundle.loadString(contentAsset));

  final DzikirLibrary library;
  final DzikirProgressStore store;
  final DzikirFeedback feedback;
  final void Function(bool enabled) keepAwake;
  final DateTime Function() clock;

  static void _wakelock(bool enabled) =>
      unawaited(WakelockPlus.toggle(enable: enabled));
}

abstract interface class DzikirFeedback {
  void onEvent(DzikirEvent event);
}

/// Three strengths so counting works without looking: a tick per count, a
/// firmer tap every 33, a strong knock when an entry or session completes.
class HapticDzikirFeedback implements DzikirFeedback {
  const HapticDzikirFeedback();

  @override
  void onEvent(DzikirEvent event) {
    switch (event) {
      case DzikirEvent.counted:
        HapticFeedback.selectionClick();
      case DzikirEvent.milestone:
        HapticFeedback.mediumImpact();
      case DzikirEvent.entryCompleted:
        HapticFeedback.heavyImpact();
      case DzikirEvent.sessionCompleted:
        HapticFeedback.heavyImpact();
        Future.delayed(
          const Duration(milliseconds: 140),
          HapticFeedback.heavyImpact,
        );
      case DzikirEvent.ignored:
        break;
    }
  }
}
