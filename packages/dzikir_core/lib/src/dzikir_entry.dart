import 'dzikir_text.dart';

/// How the UI presents an entry.
enum DzikirMode {
  /// Short text: the whole screen counts, tap or swipe anywhere is +1.
  count,

  /// Long text: the screen scrolls freely and a "done" button counts.
  read,
}

/// A text placed in a collection with its own target and evidence.
final class DzikirEntry {
  const DzikirEntry({
    required this.text,
    required this.source,
    this.target,
    this.modeOverride,
  }) : assert(target == null || target > 0);

  /// Texts longer than this many Arabic letters get [DzikirMode.read]. Ayat
  /// Kursi and Sayyidul Istighfar land above it; tasbih, tahlil and the short
  /// morning/evening du'as land below.
  static const readModeLetterThreshold = 90;

  final DzikirText text;

  /// Times to recite. Null means open-ended (free tasbih without a goal).
  final int? target;

  /// Where the practice comes from, e.g. "HR. Muslim 2692".
  final String source;

  /// Set in content when the length heuristic picks the wrong mode.
  final DzikirMode? modeOverride;

  /// The same entry with a user-chosen goal, for free tasbih (33, 99, 100 or
  /// open-ended).
  DzikirEntry withTarget(int? target) => DzikirEntry(
    text: text,
    source: source,
    target: target,
    modeOverride: modeOverride,
  );

  DzikirMode get mode =>
      modeOverride ??
      (text.letterCount > readModeLetterThreshold
          ? DzikirMode.read
          : DzikirMode.count);
}
