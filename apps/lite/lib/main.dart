import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:quran_core/quran_core.dart';

import 'app.dart';
import 'quran/bookmark_store.dart';
import 'storage.dart';
import 'tasbih/tasbih_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (quran, storage, _) = await (
    QuranLibrary.load(rootBundle.loadString),
    SharedPrefsStorage.open(),
    GlassSurface.precache(),
  ).wait;
  runApp(
    LiteApp(
      tasbih: TasbihStore(storage),
      quranLibrary: quran,
      bookmarks: BookmarkStore(storage),
    ),
  );
}
