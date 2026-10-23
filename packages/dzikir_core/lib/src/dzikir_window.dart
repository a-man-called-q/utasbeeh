/// A daily time range in local time, e.g. 03:30–11:00 for dzikir pagi.
///
/// Fixed windows are the v1 approach; prayer-time based windows can replace
/// them later without changing callers.
final class DzikirWindow {
  const DzikirWindow({required this.startMinute, required this.endMinute})
    : assert(startMinute >= 0 && startMinute < _minutesPerDay),
      assert(endMinute >= 0 && endMinute <= _minutesPerDay);

  factory DzikirWindow.fromJson(Map<String, Object?> json) {
    return DzikirWindow(
      startMinute: _parseTime(json['start'], 'start'),
      endMinute: _parseTime(json['end'], 'end'),
    );
  }

  static const _minutesPerDay = 24 * 60;

  final int startMinute;
  final int endMinute;

  /// Whether [time] falls in the window. Windows may cross midnight.
  bool contains(DateTime time) {
    final minute = time.hour * 60 + time.minute;
    return startMinute <= endMinute
        ? minute >= startMinute && minute < endMinute
        : minute >= startMinute || minute < endMinute;
  }

  static int _parseTime(Object? value, String key) {
    final match = value is String
        ? RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value)
        : null;
    final hour = match == null ? null : int.parse(match.group(1)!);
    final minute = match == null ? null : int.parse(match.group(2)!);
    if (hour == null || minute == null || hour > 24 || minute > 59) {
      throw FormatException('window.$key must be "HH:mm", got $value');
    }
    return hour * 60 + minute;
  }
}
