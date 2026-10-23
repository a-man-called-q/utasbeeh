# u-tasbeeh

Dzikr counter and Qur'an reader for iOS and Android. A Flutter monorepo run by
[moon](https://moonrepo.dev), with tools pinned by [proto](https://moonrepo.dev/proto)
and packages linked by a Dart pub workspace.

```
apps/mobile            Flutter app (iOS + Android)
packages/design_system Mix tokens, themes, fonts, GlassSurface
packages/dzikir_core   Dzikir content, counter rules, progress (pure Dart)
```

## Setup

Versions are pinned in `.prototools` (moon 2.6.1, Flutter 3.47.6). The Flutter
plugin is a community proto plugin, so proto asks you to trust this config once:

```bash
proto trust .prototools
proto install
```

## Tasks

```bash
moon run :analyze :format :test   # everything, cached
moon run mobile:run               # flutter run (add -- -d <device>)
moon run mobile:build-ios         # unsigned iOS build
moon run mobile:build-android     # debug APK
```

moon reads git, so the repository needs at least one commit before tasks run.

## Design system

Feature code imports `package:design_system/design_system.dart` only (it
re-exports `mix`).

- **Tokens** (`lib/src/tokens/`): components read semantic tokens such as
  `AppColors.inkAyah()` or `AppText.ayah.mix()`, never hex values.
- **Themes** (`lib/src/theme/`): an `AppTheme` is a light and a dark `Palette`.
  Themes change color only; type, spacing and radii are shared.
- **Glass** (`lib/src/glass/`): `GlassSurface` is the only glass widget. It
  renders as `frosted` (backdrop blur with a top sheen, the default), `liquid`
  (liquid_glass_renderer) or `solid`, per `ThemeController.glassMode`. Use
  glass for navigation (bars, sheets, the counter bead), never under Qur'an
  text, and wrap screens with several glass surfaces in a `BackdropGroup`.

### Adding a theme

1. Copy `themes/lazuardi.dart`, give it a new, permanent `id`, and fill both
   palettes. Set `isPremium: true` for a paid theme.
2. Add it to `ThemeRegistry.builtIn`.
3. `moon run design_system:test` checks that every palette defines every token.

Premium themes can always be previewed (`ThemeController.preview`) but are
only selectable once the purchase layer reports them through
`ThemeController.setUnlockedThemes`.

### Liquid glass on devices

Full refraction needs Impeller and Flutter GPU. iOS enables it via
`FLTEnableFlutterGPU` in `Info.plist`. Android does not yet, so it renders the
renderer's FakeGlass fallback.

## App logo

The ChatGPT-generated transparent master is
`apps/mobile/assets/branding/tasbeeh-logo.png`; its generation prompt is saved
alongside it in `prompt.txt`. The opaque `tasbeeh-icon.png` is used in the home
header and for the native launcher icons. Android also includes adaptive and
monochrome themed icons; iOS includes every size in the AppIcon catalog.

To regenerate the icons after changing the master (Python with Pillow):

```bash
python3 apps/mobile/tool/generate_app_icons.py
```
