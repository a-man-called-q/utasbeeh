import 'dart:convert';

import 'package:dzikir_core/dzikir_core.dart';
import 'package:test/test.dart';

/// Round-tripped through JSON so the maps are as loosely typed as real parsed
/// content and tests can mutate them freely.
Map<String, Object?> _valid() =>
    jsonDecode(jsonEncode(_validLiteral)) as Map<String, Object?>;

const _validLiteral = {
  'version': 1,
  'reference': 'test',
  'reviewed': false,
  'texts': {
    'a': {
      'arabic': 'سُبْحَانَ اللَّهِ',
      'latin': 'Subhanallah',
      'translation': 'x',
    },
  },
  'collections': [
    {
      'id': 'seq',
      'title': 'Seq',
      'kind': 'sequence',
      'entries': [
        {'text': 'a', 'target': 3, 'source': 'HR. Test'},
      ],
    },
  ],
};

void expectRejected(void Function(Map<String, Object?> json) mutate) {
  final json = _valid();
  mutate(json);
  expect(
    () => DzikirLibrary.parse(jsonEncode(json)),
    throwsA(isA<FormatException>()),
  );
}

List<Map<String, Object?>> _collections(Map<String, Object?> json) =>
    (json['collections']! as List).cast<Map<String, Object?>>();

Map<String, Object?> _firstEntry(Map<String, Object?> json) =>
    (_collections(json).first['entries']! as List).first
        as Map<String, Object?>;

void main() {
  test('parses valid content', () {
    final library = DzikirLibrary.parse(jsonEncode(_valid()));
    expect(library.byId('seq')!.entries.single.target, 3);
  });

  test('rejects an entry pointing at a missing text', () {
    expectRejected((json) => _firstEntry(json)['text'] = 'missing');
  });

  test('rejects an entry without a source', () {
    expectRejected((json) => _firstEntry(json).remove('source'));
  });

  test('rejects a zero target', () {
    expectRejected((json) => _firstEntry(json)['target'] = 0);
  });

  test('rejects a sequence entry without a target', () {
    expectRejected((json) => _firstEntry(json)['target'] = null);
  });

  test('rejects duplicate collection ids', () {
    expectRejected(
      (json) => _collections(json).add({..._collections(json).first}),
    );
  });

  test('rejects malformed windows', () {
    expectRejected(
      (json) => _collections(json).first['window'] = {
        'start': '3:30',
        'end': '11:00',
      },
    );
  });
}
