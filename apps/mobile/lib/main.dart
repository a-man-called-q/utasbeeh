import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlassSurface.precache();
  runApp(TasbeehApp(themeController: ThemeController()));
}
