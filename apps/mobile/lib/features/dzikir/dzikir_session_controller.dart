import 'dart:async';

import 'package:dzikir_core/dzikir_core.dart';
import 'package:flutter/foundation.dart';

import 'dzikir_services.dart';

/// Connects a [DzikirSession] to the UI: feedback per count, progress saved
/// after every change, completion recorded once.
class DzikirSessionController extends ChangeNotifier {
  DzikirSessionController({required this.session, required this.services});

  /// Starts [collection], resuming stored progress when it still applies.
  factory DzikirSessionController.forCollection(
    DzikirCollection collection,
    DzikirServices services,
  ) => DzikirSessionController(
    session: DzikirSession(
      collection,
      resume: services.store.progressFor(collection.id),
      now: services.clock(),
    ),
    services: services,
  );

  factory DzikirSessionController.free(
    DzikirEntry entry,
    DzikirServices services,
  ) => DzikirSessionController(
    session: DzikirSession.free(
      entry,
      resume: services.store.progressFor(
        DzikirSession.freeCollectionId(entry.text.id),
      ),
      now: services.clock(),
    ),
    services: services,
  );

  final DzikirSession session;
  final DzikirServices services;

  DzikirEvent? _lastEvent;

  /// The latest event, for one-off motion such as the completion pulse.
  DzikirEvent? get lastEvent => _lastEvent;

  void increment() {
    final event = session.increment();
    if (event == DzikirEvent.ignored) return;
    _lastEvent = event;
    if (services.settings.vibrate) services.feedback.onEvent(event);
    _persist(event);
    notifyListeners();
  }

  /// Takes back a stray count.
  void decrement() => _step(session.decrement());

  void previous() => _step(session.previous());

  void next() => _step(session.next());

  /// Next sentence of a text read one part at a time.
  void nextPart() => _step(session.nextPart());

  void previousPart() => _step(session.previousPart());

  void _step(bool changed) {
    if (!changed) return;
    _lastEvent = null;
    nudge();
    _persist(null);
    notifyListeners();
  }

  /// A light tick for steps the screen owns, such as moving to the next
  /// sentence of a long text.
  void nudge() {
    if (services.settings.vibrate) services.feedback.onStep();
  }

  void _persist(DzikirEvent? event) {
    final store = services.store;
    final now = services.clock();
    final id = session.collection.id;
    final progress = session.progress(now: now);
    if (progress == null) {
      unawaited(store.clearProgress(id));
    } else {
      unawaited(store.saveProgress(progress));
    }
    if (event == DzikirEvent.sessionCompleted) {
      unawaited(store.markCompleted(id, now));
    }
  }
}
