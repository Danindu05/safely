import 'dart:async';

import 'app_logger.dart';

typedef RetryDecider = bool Function(Object error);

class RetryHelper {
  const RetryHelper._();

  static Future<T> run<T>({
    required String label,
    required Future<T> Function() operation,
    int attempts = 3,
    Duration initialDelay = const Duration(milliseconds: 400),
    RetryDecider? shouldRetry,
  }) async {
    Object? lastError;

    for (int attempt = 1; attempt <= attempts; attempt++) {
      try {
        if (attempt > 1) {
          AppLogger.warning('$label retry $attempt of $attempts');
        }
        return await operation();
      } catch (error, stackTrace) {
        lastError = error;

        final bool canRetry =
            attempt < attempts &&
            (shouldRetry?.call(error) ?? _defaultShouldRetry(error));
        if (!canRetry) {
          AppLogger.error(
            '$label failed after $attempt attempt(s)',
            error: error,
            stackTrace: stackTrace,
          );
          rethrow;
        }

        final int multiplier = 1 << (attempt - 1);
        await Future<void>.delayed(initialDelay * multiplier);
      }
    }

    throw lastError ??
        StateError('$label failed without exposing a concrete exception.');
  }

  static bool _defaultShouldRetry(Object error) {
    return error is! ArgumentError &&
        error is! FormatException &&
        error is! StateError;
  }
}
