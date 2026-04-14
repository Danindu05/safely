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

  static String formatTime(DateTime value) {
    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String minute = value.minute.toString().padLeft(2, '0');
    final String meridiem = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $meridiem';
  }

  static String formatRelative(DateTime value, {DateTime? reference}) {
    final DateTime now = reference ?? DateTime.now();
    final Duration difference = now.difference(value);

    if (difference.inSeconds < 60) {
      final int seconds = difference.inSeconds.clamp(0, 59);
      return '${seconds}s ago';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    return formatShort(value);
  }

  static String formatSectionLabel(DateTime value, {DateTime? reference}) {
    final DateTime now = reference ?? DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(value.year, value.month, value.day);
    final int dayDelta = today.difference(target).inDays;

    if (dayDelta == 0) {
      return 'Today';
    }
    if (dayDelta <= 7) {
      return 'Earlier';
    }
    return 'Older';
  }
}
