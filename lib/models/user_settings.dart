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
    );
  }
}
