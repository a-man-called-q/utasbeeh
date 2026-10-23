/// Uthmani text puts a space before each pause sign (ۖ ۗ ۚ ۛ …), so a sign at
/// the end of a line lands on that space and floats loose. A mushaf prints
/// it over the end of the word before it, so join it there. For display
/// only; stored text is never changed.
String attachWaqfMarks(String arabic) =>
    arabic.replaceAllMapped(RegExp('\\s+([\u06D6-\u06DC])'), (m) => m[1]!);
