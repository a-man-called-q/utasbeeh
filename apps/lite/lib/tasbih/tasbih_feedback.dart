import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// What a count feels like. Swapped out in tests.
abstract interface class TasbihFeedback {
  /// [count] is the new total, so every 33rd can feel different.
  void onCount(int count);

  /// −1 or reset: a deliberate step that is not a count.
  void onStep();
}

/// A tick per count and a firmer tap every 33, so counting works without
/// looking.
///
/// Android vibrates the motor directly: system haptics there depend on the
/// phone's "touch feedback" setting and are often too faint to feel. iOS
/// keeps the Taptic Engine's haptics.
class HapticTasbihFeedback implements TasbihFeedback {
  const HapticTasbihFeedback();

  static bool get _android => defaultTargetPlatform == TargetPlatform.android;

  @override
  void onCount(int count) {
    final milestone = count % 33 == 0;
    if (_android) {
      milestone ? _buzz(70, 220) : _buzz(30, 140);
    } else if (milestone) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
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
