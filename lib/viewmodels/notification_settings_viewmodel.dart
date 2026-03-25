import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';

class NotificationSettingsViewModel extends ChangeNotifier {
  NotificationSettingsViewModel(this._authRepository);

  final AuthRepository _authRepository;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool repeatedAlertsEnabled = true;
  bool highPriorityOnly = false;
  bool isSigningOut = false;

  void toggleSound(bool value) {
    soundEnabled = value;
    notifyListeners();
  }

  void toggleVibration(bool value) {
    vibrationEnabled = value;
    notifyListeners();
  }

  void toggleRepeatedAlerts(bool value) {
    repeatedAlertsEnabled = value;
    notifyListeners();
  }

  void toggleHighPriorityOnly(bool value) {
    highPriorityOnly = value;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (isSigningOut) {
      return;
    }

    isSigningOut = true;
    notifyListeners();

    try {
      await _authRepository.signOut();
    } finally {
      isSigningOut = false;
      notifyListeners();
    }
  }
}
