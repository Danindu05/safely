import '../core/constants/app_constants.dart';

class UserSettings {
  const UserSettings({
    required this.userId,
    required this.lowBatteryWarningPercent,
    required this.lowBatteryCriticalPercent,
    required this.checkInEnabled,
    required this.checkInIntervalMinutes,
    required this.autoCheckInEnabled,
    required this.audioRecordingEnabled,
    required this.geofencingEnabled,
    required this.liveLocationEnabled,
    required this.trustedPlaceModeEnabled,
    required this.nightModeMonitoringEnabled,
    required this.sosNotificationsEnabled,
    required this.batteryNotificationsEnabled,
    required this.geofenceNotificationsEnabled,
    required this.checkInNotificationsEnabled,
    required this.emergencyDetectionEnabled,
    required this.fallDetectionEnabled,
    required this.movementDetectionEnabled,
  });

  final String userId;
  final int lowBatteryWarningPercent;
  final int lowBatteryCriticalPercent;
  final bool checkInEnabled;
  final int checkInIntervalMinutes;
  final bool autoCheckInEnabled;
  final bool audioRecordingEnabled;
  final bool geofencingEnabled;
  final bool liveLocationEnabled;
  final bool trustedPlaceModeEnabled;
  final bool nightModeMonitoringEnabled;
  final bool sosNotificationsEnabled;
  final bool batteryNotificationsEnabled;
  final bool geofenceNotificationsEnabled;
  final bool checkInNotificationsEnabled;
  final bool emergencyDetectionEnabled;
  final bool fallDetectionEnabled;
  final bool movementDetectionEnabled;

  factory UserSettings.defaults(String userId) {
    return UserSettings(
      userId: userId,
      lowBatteryWarningPercent: AppConstants.lowBatteryWarningFallback,
      lowBatteryCriticalPercent: AppConstants.lowBatteryCriticalFallback,
      checkInEnabled: true,
      checkInIntervalMinutes: 60,
      autoCheckInEnabled: false,
      audioRecordingEnabled: true,
      geofencingEnabled: false,
      liveLocationEnabled: true,
      trustedPlaceModeEnabled: false,
      nightModeMonitoringEnabled: false,
      sosNotificationsEnabled: true,
      batteryNotificationsEnabled: true,
      geofenceNotificationsEnabled: true,
      checkInNotificationsEnabled: true,
      emergencyDetectionEnabled: true,
      fallDetectionEnabled: true,
      movementDetectionEnabled: true,
    );
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      userId: (map[FirestoreFields.userId] as String?)?.trim() ?? '',
      lowBatteryWarningPercent:
          (map[FirestoreFields.lowBatteryWarningPercent] as num?)?.toInt() ??
          AppConstants.lowBatteryWarningFallback,
      lowBatteryCriticalPercent:
          (map[FirestoreFields.lowBatteryCriticalPercent] as num?)?.toInt() ??
          AppConstants.lowBatteryCriticalFallback,
      checkInEnabled: map[FirestoreFields.checkInEnabled] as bool? ?? true,
      checkInIntervalMinutes:
          (map[FirestoreFields.checkInIntervalMinutes] as num?)?.toInt() ?? 60,
      autoCheckInEnabled:
          map[FirestoreFields.autoCheckInEnabled] as bool? ?? false,
      audioRecordingEnabled:
          map[FirestoreFields.audioRecordingEnabled] as bool? ?? true,
      geofencingEnabled:
          map[FirestoreFields.geofencingEnabled] as bool? ?? false,
      liveLocationEnabled:
          map[FirestoreFields.liveLocationEnabled] as bool? ?? true,
      trustedPlaceModeEnabled:
          map[FirestoreFields.trustedPlaceModeEnabled] as bool? ?? false,
      nightModeMonitoringEnabled:
          map[FirestoreFields.nightModeMonitoringEnabled] as bool? ?? false,
      sosNotificationsEnabled:
          map[FirestoreFields.sosNotificationsEnabled] as bool? ?? true,
      batteryNotificationsEnabled:
          map[FirestoreFields.batteryNotificationsEnabled] as bool? ?? true,
      geofenceNotificationsEnabled:
          map[FirestoreFields.geofenceNotificationsEnabled] as bool? ?? true,
      checkInNotificationsEnabled:
          map[FirestoreFields.checkInNotificationsEnabled] as bool? ?? true,
      emergencyDetectionEnabled:
          map[FirestoreFields.emergencyDetectionEnabled] as bool? ?? true,
      fallDetectionEnabled:
          map[FirestoreFields.fallDetectionEnabled] as bool? ?? true,
      movementDetectionEnabled:
          map[FirestoreFields.movementDetectionEnabled] as bool? ?? true,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      FirestoreFields.userId: userId,
      FirestoreFields.lowBatteryWarningPercent: lowBatteryWarningPercent,
      FirestoreFields.lowBatteryCriticalPercent: lowBatteryCriticalPercent,
      FirestoreFields.checkInEnabled: checkInEnabled,
      FirestoreFields.checkInIntervalMinutes: checkInIntervalMinutes,
      FirestoreFields.autoCheckInEnabled: autoCheckInEnabled,
      FirestoreFields.audioRecordingEnabled: audioRecordingEnabled,
      FirestoreFields.geofencingEnabled: geofencingEnabled,
      FirestoreFields.liveLocationEnabled: liveLocationEnabled,
      FirestoreFields.trustedPlaceModeEnabled: trustedPlaceModeEnabled,
      FirestoreFields.nightModeMonitoringEnabled: nightModeMonitoringEnabled,
      FirestoreFields.sosNotificationsEnabled: sosNotificationsEnabled,
      FirestoreFields.batteryNotificationsEnabled: batteryNotificationsEnabled,
      FirestoreFields.geofenceNotificationsEnabled:
          geofenceNotificationsEnabled,
      FirestoreFields.checkInNotificationsEnabled: checkInNotificationsEnabled,
      FirestoreFields.emergencyDetectionEnabled: emergencyDetectionEnabled,
      FirestoreFields.fallDetectionEnabled: fallDetectionEnabled,
      FirestoreFields.movementDetectionEnabled: movementDetectionEnabled,
    };
  }

  UserSettings copyWith({
    int? lowBatteryWarningPercent,
    int? lowBatteryCriticalPercent,
    bool? checkInEnabled,
    int? checkInIntervalMinutes,
    bool? autoCheckInEnabled,
    bool? audioRecordingEnabled,
    bool? geofencingEnabled,
    bool? liveLocationEnabled,
    bool? trustedPlaceModeEnabled,
    bool? nightModeMonitoringEnabled,
    bool? sosNotificationsEnabled,
    bool? batteryNotificationsEnabled,
    bool? geofenceNotificationsEnabled,
    bool? checkInNotificationsEnabled,
    bool? emergencyDetectionEnabled,
    bool? fallDetectionEnabled,
    bool? movementDetectionEnabled,
  }) {
    return UserSettings(
      userId: userId,
      lowBatteryWarningPercent:
          lowBatteryWarningPercent ?? this.lowBatteryWarningPercent,
      lowBatteryCriticalPercent:
          lowBatteryCriticalPercent ?? this.lowBatteryCriticalPercent,
      checkInEnabled: checkInEnabled ?? this.checkInEnabled,
      checkInIntervalMinutes:
          checkInIntervalMinutes ?? this.checkInIntervalMinutes,
      autoCheckInEnabled: autoCheckInEnabled ?? this.autoCheckInEnabled,
      audioRecordingEnabled:
          audioRecordingEnabled ?? this.audioRecordingEnabled,
      geofencingEnabled: geofencingEnabled ?? this.geofencingEnabled,
      liveLocationEnabled: liveLocationEnabled ?? this.liveLocationEnabled,
      trustedPlaceModeEnabled:
          trustedPlaceModeEnabled ?? this.trustedPlaceModeEnabled,
      nightModeMonitoringEnabled:
          nightModeMonitoringEnabled ?? this.nightModeMonitoringEnabled,
      sosNotificationsEnabled:
          sosNotificationsEnabled ?? this.sosNotificationsEnabled,
      batteryNotificationsEnabled:
          batteryNotificationsEnabled ?? this.batteryNotificationsEnabled,
      geofenceNotificationsEnabled:
          geofenceNotificationsEnabled ?? this.geofenceNotificationsEnabled,
      checkInNotificationsEnabled:
          checkInNotificationsEnabled ?? this.checkInNotificationsEnabled,
      emergencyDetectionEnabled:
          emergencyDetectionEnabled ?? this.emergencyDetectionEnabled,
      fallDetectionEnabled: fallDetectionEnabled ?? this.fallDetectionEnabled,
      movementDetectionEnabled:
          movementDetectionEnabled ?? this.movementDetectionEnabled,
    );
  }
}
