import 'dart:async';

import 'package:dzikir_core/dzikir_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'dzikir_progress_store.dart';

/// Everything the dzikir screens need from outside, bundled so tests can
/// swap storage, haptics, wakelock and the clock.
class DzikirServices {
  DzikirServices({
    required this.library,
    required this.store,
    this.feedback = const HapticDzikirFeedback(),
    this.keepAwake = _wakelock,
    this.clock = DateTime.now,
    DzikirSettings? settings,
  }) : settings = settings ?? DzikirSettings();

  static const contentAsset = 'packages/dzikir_core/content/dzikir.json';

  static Future<DzikirLibrary> loadLibrary(AssetBundle bundle) async =>
      DzikirLibrary.parse(await bundle.loadString(contentAsset));

  final DzikirLibrary library;
  final DzikirProgressStore store;
  final DzikirFeedback feedback;
  final void Function(bool enabled) keepAwake;
  final DateTime Function() clock;
  final DzikirSettings settings;

  static void _wakelock(bool enabled) =>
      unawaited(WakelockPlus.toggle(enable: enabled));
}

/// Which lines of a recitation show. Those who know a text by heart often
/// want the Arabic alone; learners want all three.
enum DzikirTextLayers {
  arabic,
  arabicLatin,
  all;

  bool get latin => this != arabic;
  bool get translation => this == all;
}

/// Arabic text size, for readers who need it larger.
enum DzikirArabicSize {
  small(0.85),
  medium(1),
  large(1.2);

  const DzikirArabicSize(this.scale);

  final double scale;
}

/// Session preferences that are not about the theme. Not persisted yet, like
/// the theme choices.
class DzikirSettings extends ChangeNotifier {
  DzikirSettings({
    this._vibrate = true,
    this._layers = DzikirTextLayers.all,
    this._arabicSize = DzikirArabicSize.medium,
  });

  bool _vibrate;
  DzikirTextLayers _layers;
  DzikirArabicSize _arabicSize;

  /// Whether counting vibrates.
  bool get vibrate => _vibrate;
  set vibrate(bool value) => _set(() => _vibrate = value, value == _vibrate);

  DzikirTextLayers get layers => _layers;
  set layers(DzikirTextLayers value) =>
      _set(() => _layers = value, value == _layers);

  DzikirArabicSize get arabicSize => _arabicSize;
  set arabicSize(DzikirArabicSize value) =>
      _set(() => _arabicSize = value, value == _arabicSize);

  void _set(void Function() apply, bool unchanged) {
    if (unchanged) return;
    apply();
    notifyListeners();
  }
}

abstract interface class DzikirFeedback {
  void onEvent(DzikirEvent event);

  /// A deliberate step that is not a count: −1, previous or next entry.
  void onStep();
}

/// Three strengths so counting works without looking: a tick per count, a
/// firmer tap every 33, a strong knock when an entry or session completes.
///
/// Android vibrates the motor directly: system haptics there depend on the
/// phone's "touch feedback" setting and a selection click is often too faint
/// to feel. iOS keeps the Taptic Engine's haptics.
class HapticDzikirFeedback implements DzikirFeedback {
  const HapticDzikirFeedback();

  static bool get _android => defaultTargetPlatform == TargetPlatform.android;

  @override
  void onEvent(DzikirEvent event) {
    if (_android) {
      switch (event) {
        case DzikirEvent.counted:
          _buzz(30, 140);
        case DzikirEvent.milestone:
          _buzz(70, 220);
        case DzikirEvent.entryCompleted:
          _buzz(140, 255);
        case DzikirEvent.sessionCompleted:
          unawaited(
            Vibration.vibrate(
              pattern: const [0, 140, 110, 220],
              intensities: const [0, 255, 0, 255],
            ),
          );
        case DzikirEvent.ignored:
          break;
      }
      return;
    }
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

  @override
  void onStep() {
    if (_android) {
      _buzz(15, 90);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void _buzz(int ms, int amplitude) =>
      unawaited(Vibration.vibrate(duration: ms, amplitude: amplitude));
}
