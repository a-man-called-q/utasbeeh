# dzikir_core

Dzikir content, counting and progress for the Tasbeeh app. Pure Dart, no
Flutter, so the rules are tested with `moon run dzikir_core:test`.

- `lib/content/dzikir.json`: all texts and collections. Texts are written once
  under `texts` and referenced by id from each collection with their own
  `target` and `source`. Bump `version` on every content change.
- `DzikirSession`: counts through a collection and reports a `DzikirEvent`
  per count (counted, milestone, entryCompleted, sessionCompleted, ignored).
  No undo by design; persist `progress()` after each count.
- `DzikirEntry.mode`: texts over 90 Arabic letters are read (scroll plus a
  done button); shorter ones are counted (tap or swipe anywhere). Override
  per entry with `"mode"` in the JSON.

## Content status

`reviewed` is `false`. The texts, counts and hadith references follow Hisnul
Muslim but were entered by hand and must be checked by someone qualified
before release. `content_test.dart` validates structure only, not wording.
