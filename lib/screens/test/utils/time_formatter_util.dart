class TimeFormatterUtil {
  /// Converts current time to an ISO 8601 string for Realtime Database
  static String getCurrentTimestampForDB() {
    return DateTime.now().toUtc().toIso8601String();
  }

  /// Formats timestamp for Guardian Dashboard display
  static String formatAlertTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
