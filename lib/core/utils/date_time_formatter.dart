class DateTimeFormatter {
  const DateTimeFormatter._();

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatShort(DateTime value) {
    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String minute = value.minute.toString().padLeft(2, '0');
    final String meridiem = value.hour >= 12 ? 'PM' : 'AM';
    final String month = _months[value.month - 1];
    return '$month ${value.day}, ${value.year} - $hour:$minute $meridiem';
  }
}
