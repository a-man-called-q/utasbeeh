import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'features/dzikir/dzikir_progress_store.dart';
import 'features/dzikir/dzikir_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (library, store, _) = await (
    DzikirServices.loadLibrary(rootBundle),
    SharedPrefsDzikirProgressStore.open(),
    GlassSurface.precache(),
  ).wait;
  runApp(
    TasbeehApp(
      themeController: ThemeController(),
      dzikirServices: DzikirServices(library: library, store: store),
    ),
  );
}
