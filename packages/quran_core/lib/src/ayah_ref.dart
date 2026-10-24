/// An ayah's address, e.g. 2:255.
typedef AyahRef = ({int surah, int ayah});

/// `2:255`, the form [parseAyahRef] reads back.
String formatAyahRef(AyahRef ref) => '${ref.surah}:${ref.ayah}';

/// Reads `2:255`; null for anything else.
AyahRef? parseAyahRef(String raw) {
  final parts = raw.trim().split(':');
  if (parts.length != 2) return null;
  final surah = int.tryParse(parts[0].trim());
  final ayah = int.tryParse(parts[1].trim());
  return surah == null || ayah == null ? null : (surah: surah, ayah: ayah);
}

const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

/// End-of-ayah marker in ornate parentheses with Arabic-Indic digits,
/// e.g. ﴿١٢﴾. Written in logical (RTL) order.
String ayahMarker(int number) {
  final digits = number
      .toString()
      .split('')
      .map((d) => _arabicDigits[int.parse(d)])
      .join();
  return '﴿$digits﴾';
}
