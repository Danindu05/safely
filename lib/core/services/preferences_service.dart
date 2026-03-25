import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class PreferencesService {
  PreferencesService(this._preferences);

  final SharedPreferences _preferences;

  bool get onboardingSeen {
    return _preferences.getBool(AppConstants.onboardingSeenKey) ?? false;
  }

  Future<void> setOnboardingSeen(bool value) {
    return _preferences.setBool(AppConstants.onboardingSeenKey, value);
  }

  bool get permissionSetupCompleted {
    return _preferences.getBool(AppConstants.permissionSetupCompletedKey) ??
        false;
  }

  Future<void> setPermissionSetupCompleted(bool value) {
    return _preferences.setBool(
      AppConstants.permissionSetupCompletedKey,
      value,
    );
  }

  int? get lastBatteryAlertLevel {
    return _preferences.getInt(AppConstants.lastBatteryAlertLevelKey);
  }

  Future<void> setLastBatteryAlertLevel(int? level) async {
    if (level == null) {
      await _preferences.remove(AppConstants.lastBatteryAlertLevelKey);
      return;
    }
    await _preferences.setInt(AppConstants.lastBatteryAlertLevelKey, level);
  }

  String? get activeAlertId {
    return _preferences.getString(AppConstants.activeAlertIdKey);
  }

  Future<void> setActiveAlertId(String? alertId) async {
    if (alertId == null || alertId.isEmpty) {
      await _preferences.remove(AppConstants.activeAlertIdKey);
      return;
    }
    await _preferences.setString(AppConstants.activeAlertIdKey, alertId);
  }

  String? get lastNightMonitoringAlertSession {
    return _preferences.getString(
      AppConstants.lastNightMonitoringAlertSessionKey,
    );
  }

  Future<void> setLastNightMonitoringAlertSession(String? sessionId) async {
    if (sessionId == null || sessionId.isEmpty) {
      await _preferences.remove(
        AppConstants.lastNightMonitoringAlertSessionKey,
      );
      return;
    }

    await _preferences.setString(
      AppConstants.lastNightMonitoringAlertSessionKey,
      sessionId,
    );
  }
}
