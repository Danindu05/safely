import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/firebase_error_mapper.dart';

class BaseViewModel extends ChangeNotifier {
  bool _isBusy = false;
  String? _errorMessage;
  String? _infoMessage;

  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;

  void clearMessages() {
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();
  }

  void setInfo(String? message) {
    _infoMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(Object error) {
    _errorMessage = FirebaseErrorMapper.map(error);
    _infoMessage = null;
    notifyListeners();
  }

  Future<T?> guard<T>(
    Future<T> Function() action, {
    String? operationName,
    Duration timeout = const Duration(
      seconds: AppConstants.asyncOperationTimeoutSeconds,
    ),
  }) async {
    _errorMessage = null;
    _infoMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      final Future<T> operation = action();
      return await operation.timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'This is taking longer than expected. Please try again.',
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        operationName ?? runtimeType.toString(),
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = FirebaseErrorMapper.map(error);
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
