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

  String? get activeGeofenceZoneId {
    return _preferences.getString(AppConstants.activeGeofenceZoneIdKey);
  }

  Future<void> setActiveGeofenceZoneId(String? zoneId) async {
    if (zoneId == null || zoneId.isEmpty) {
      await _preferences.remove(AppConstants.activeGeofenceZoneIdKey);
      return;
    }

    await _preferences.setString(AppConstants.activeGeofenceZoneIdKey, zoneId);
  }

  String? get safetyTimerStateJson {
    return _preferences.getString(AppConstants.safetyTimerStateKey);
  }

  Future<void> setSafetyTimerStateJson(String? value) async {
    if (value == null || value.isEmpty) {
      await _preferences.remove(AppConstants.safetyTimerStateKey);
      return;
    }

    await _preferences.setString(AppConstants.safetyTimerStateKey, value);
  }

  String? get routeTrackingStateJson {
    return _preferences.getString(AppConstants.routeTrackingStateKey);
  }

  Future<void> setRouteTrackingStateJson(String? value) async {
    if (value == null || value.isEmpty) {
      await _preferences.remove(AppConstants.routeTrackingStateKey);
      return;
    }

    await _preferences.setString(AppConstants.routeTrackingStateKey, value);
  }

  String? get backgroundCheckInPromptStartedAt {
    return _preferences.getString(
      AppConstants.backgroundCheckInPromptStartedAtKey,
    );
  }

  Future<void> setBackgroundCheckInPromptStartedAt(String? value) async {
    if (value == null || value.isEmpty) {
      await _preferences.remove(
        AppConstants.backgroundCheckInPromptStartedAtKey,
      );
      return;
    }

    await _preferences.setString(
      AppConstants.backgroundCheckInPromptStartedAtKey,
      value,
    );
  }

  String? get pendingGeofenceEventJson {
    return _preferences.getString(AppConstants.pendingGeofenceEventJsonKey);
  }

  Future<void> setPendingGeofenceEventJson(String? value) async {
    if (value == null || value.isEmpty) {
      await _preferences.remove(AppConstants.pendingGeofenceEventJsonKey);
      return;
    }

    await _preferences.setString(
      AppConstants.pendingGeofenceEventJsonKey,
      value,
    );
  }
}
