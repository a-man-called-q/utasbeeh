# quran_core

The Qur'an text, surah index and ayah addresses shared by `apps/mobile` and
`apps/lite`. Pure Dart, tested with `moon run quran_core:test`.

- `lib/content/`: Tanzil's Uthmani text and the interim English translation,
  bundled verbatim (see `SOURCES.md` there). An app lists both files under
  `flutter: assets:` as `packages/quran_core/content/...` and loads them with
  `QuranLibrary.load(rootBundle.loadString)`.
- `AyahRef`: an ayah's address. `formatAyahRef` and `parseAyahRef` are the
  `2:255` form both apps store bookmarks in.
