/// Utility class cho date/time formatting — tránh duplicate logic rải rác
class DateFormatter {
  DateFormatter._();

  static String format(DateTime dt) =>
      '${_pad(dt.day)}/${_pad(dt.month)}/${dt.year}';

  static String formatWithTime(DateTime dt) =>
      '${_pad(dt.day)}/${_pad(dt.month)}/${dt.year} ${_pad(dt.hour)}:${_pad(dt.minute)}';

  static String formatTime(DateTime dt) =>
      '${_pad(dt.hour)}:${_pad(dt.minute)}';

  static String formatMonthYear(int month, int year) => 'Tháng $month/$year';

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
