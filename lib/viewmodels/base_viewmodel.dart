import 'package:flutter/material.dart';

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

  Future<T?> guard<T>(Future<T> Function() action) async {
    _errorMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      return await action();
    } catch (error) {
      _errorMessage = FirebaseErrorMapper.map(error);
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
