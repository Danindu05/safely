import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void info(String message) {
    _log('INFO', message);
  }

  static void warning(String message) {
    _log('WARN', message);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    final StringBuffer buffer = StringBuffer(message);
    if (error != null) {
      buffer.write(' | error=$error');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    _log('ERROR', buffer.toString());
  }

  static void _log(String level, String message) {
    debugPrint('[$level][Safely] $message');
  }
}
