import 'dart:convert';

import 'dzikir_collection.dart';
import 'dzikir_entry.dart';
import 'dzikir_text.dart';
import 'dzikir_window.dart';

/// All dzikir content shipped with the app, parsed from the bundled JSON
/// (`lib/content/dzikir.json`).
final class DzikirLibrary {
  const DzikirLibrary({
    required this.version,
    required this.reference,
    required this.reviewed,
    required this.collections,
  });

  /// Parses and validates content. Throws [FormatException] naming the
  /// offending path, so a bad content edit fails loudly in tests.
  factory DzikirLibrary.parse(String source) {
    final json = jsonDecode(source);
    if (json is! Map<String, Object?>) {
      throw const FormatException('Root must be an object');
    }

    final textsJson = _map(json['texts'], 'texts');
    final texts = {
      for (final MapEntry(:key, :value) in textsJson.entries)
        key: DzikirText.fromJson(key, _map(value, 'texts.$key')),
    };

    final collectionIds = <String>{};
    final collections = [
      for (final (index, raw) in _list(
        json['collections'],
        'collections',
      ).indexed)
        _parseCollection(
          _map(raw, 'collections[$index]'),
          texts,
          collectionIds,
        ),
    ];

    final version = json['version'];
    final reference = json['reference'];
    final reviewed = json['reviewed'];
    if (version is! int || reference is! String || reviewed is! bool) {
      throw const FormatException(
        'version (int), reference (string) and reviewed (bool) are required',
      );
    }

    return DzikirLibrary(
      version: version,
      reference: reference,
      reviewed: reviewed,
      collections: collections,
    );
  }

  /// Bumped whenever content changes, so stored progress can be checked.
  final int version;

  /// The book the texts and counts follow, e.g. Hisnul Muslim.
  final String reference;

  /// False until someone qualified has checked every text, count and source
  /// against [reference]. Do not ship content with this set to false.
  final bool reviewed;

  final List<DzikirCollection> collections;

  DzikirCollection? byId(String id) {
    for (final collection in collections) {
      if (collection.id == id) return collection;
    }
    return null;
  }

  /// The sequence whose window contains [now], e.g. pagi after Subuh.
  DzikirCollection? suggestedAt(DateTime now) {
    for (final collection in collections) {
      if (collection.window?.contains(now) ?? false) return collection;
    }
    return null;
  }

  static DzikirCollection _parseCollection(
    Map<String, Object?> json,
    Map<String, DzikirText> texts,
    Set<String> seenIds,
  ) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Every collection needs a string id');
    }
    if (!seenIds.add(id)) {
      throw FormatException('Duplicate collection id "$id"');
    }
    final title = json['title'];
    if (title is! String || title.isEmpty) {
      throw FormatException('collections.$id.title is required');
    }
    final kind = DzikirCollectionKind.values.asNameMap()[json['kind']];
    if (kind == null) {
      throw FormatException('collections.$id.kind must be sequence or presets');
    }
    final entries = [
      for (final (index, raw) in _list(json['entries'], '$id.entries').indexed)
        _parseEntry(_map(raw, '$id.entries[$index]'), texts, '$id[$index]'),
    ];
    if (entries.isEmpty) {
      throw FormatException('collections.$id has no entries');
    }
    if (kind == DzikirCollectionKind.sequence &&
        entries.any((entry) => entry.target == null)) {
      throw FormatException('collections.$id: sequence entries need a target');
    }
    final window = json['window'];

    return DzikirCollection(
      id: id,
      title: title,
      subtitle: json['subtitle'] as String?,
      kind: kind,
      entries: entries,
      window: window == null
          ? null
          : DzikirWindow.fromJson(_map(window, '$id.window')),
    );
  }

  static DzikirEntry _parseEntry(
    Map<String, Object?> json,
    Map<String, DzikirText> texts,
    String path,
  ) {
    final text = texts[json['text']];
    if (text == null) {
      throw FormatException('$path.text "${json['text']}" is not in texts');
    }
    final target = json['target'];
    if (target != null && (target is! int || target <= 0)) {
      throw FormatException('$path.target must be a positive int or null');
    }
    final source = json['source'];
    if (source is! String || source.trim().isEmpty) {
      throw FormatException('$path.source is required');
    }
    final mode = json['mode'];
    final modeOverride = mode == null
        ? null
        : DzikirMode.values.asNameMap()[mode] ??
              (throw FormatException('$path.mode must be count or read'));

    return DzikirEntry(
      text: text,
      target: target as int?,
      source: source,
      modeOverride: modeOverride,
    );
  }

  static Map<String, Object?> _map(Object? value, String path) =>
      value is Map<String, Object?>
      ? value
      : throw FormatException('$path must be an object');

  static List<Object?> _list(Object? value, String path) =>
      value is List ? value : throw FormatException('$path must be a list');
}
