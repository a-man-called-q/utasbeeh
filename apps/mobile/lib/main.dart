import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'features/dzikir/dzikir_progress_store.dart';
import 'features/dzikir/dzikir_services.dart';
import 'features/quran/quran_library.dart';
import 'features/quran/quran_store.dart';
import 'features/settings/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (library, quran, store, settingsBackend, _) = await (
    DzikirServices.loadLibrary(rootBundle),
    QuranLibrary.load(rootBundle),
    SharedPrefsDzikirProgressStore.open(),
    SharedPrefsSettingsBackend.open(),
    GlassSurface.precache(),
  ).wait;
  final settings = SettingsStore(settingsBackend);
  runApp(
    TasbeehApp(
      themeController: settings.restoreTheme(),
      dzikirServices: DzikirServices(
        library: library,
        store: store,
        settings: settings.restoreDzikirSettings(),
      ),
      quranLibrary: quran,
      quranStore: QuranStore(settingsBackend),
    ),
  );
}
