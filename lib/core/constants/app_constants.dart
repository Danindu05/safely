class AppConstants {
  const AppConstants._();

  static const String appName = 'Safely';
  static const double pagePadding = 16;
  static const double cardRadius = 16;
  static const double buttonHeight = 56;
  static const double sosButtonSize = 220;
  static const int locationUpdateIntervalSeconds = 15;
  static const int asyncOperationTimeoutSeconds = 20;
  static const int routeLoadingTimeoutSeconds = 8;
  static const int maxCriticalWriteAttempts = 3;
  static const int backgroundMonitorIntervalMinutes = 2;
  static const int runtimeHeartbeatIntervalSeconds = 1;
  static const int routeEvaluationIntervalSeconds = 15;
  static const int liveLocationDistanceFilterMeters = 5;
  static const int emergencyDetectionConfirmationSeconds = 12;
  static const int emergencyDetectionCooldownSeconds = 45;
  static const int lowBatteryWarningFallback = 15;
  static const int lowBatteryCriticalFallback = 5;
  static const int checkInPromptTimeoutSeconds = 60;
  static const int backgroundMonitorIntervalMinimumMinutes = 15;
  static const int nightMonitoringStartHour = 22;
  static const int nightMonitoringEndHour = 6;
  static const double routeDeviationThresholdMeters = 75;
  static const double routeCompletionThresholdMeters = 75;
  static const int routeFetchTimeoutSeconds = 8;
  static const String osrmRouteHost = 'router.project-osrm.org';
  static const String onboardingSeenKey = 'onboarding_seen';
  static const String permissionSetupCompletedKey =
      'permission_setup_completed';
  static const String lastBatteryAlertLevelKey = 'last_battery_alert_level';
  static const String activeAlertIdKey = 'active_alert_id';
  static const String lastNightMonitoringAlertSessionKey =
      'last_night_monitoring_alert_session';
  static const String activeGeofenceZoneIdKey = 'active_geofence_zone_id';
  static const String safetyTimerStateKey = 'safety_timer_state';
  static const String routeTrackingStateKey = 'route_tracking_state';
  static const String backgroundCheckInPromptStartedAtKey =
      'background_check_in_prompt_started_at';
  static const String pendingGeofenceEventJsonKey =
      'pending_geofence_event_json';
  static const String backgroundMonitorTaskUniqueName =
      'safely_background_monitor';
  static const String backgroundMonitorTaskName =
      'safely_background_monitor_task';
  static const String geofenceMethodChannel = 'com.bitlynx.safely/geofencing';
  static const String alertsNotificationChannelId = 'safely_alerts';
  static const String alertsNotificationChannelName = 'Safely Alerts';
  static const String alertsNotificationChannelDescription =
      'Critical guardian alerts for Safely.';
  static const String flutterNotificationClickAction =
      'FLUTTER_NOTIFICATION_CLICK';
  static const String openStreetMapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String openStreetMapCopyrightUrl =
      'https://www.openstreetmap.org/copyright';
  static const String mapUserAgentPackageName = 'com.bitlynx.safely';
}

class FirestoreCollections {
  const FirestoreCollections._();

  static const String users = 'users';
  static const String medicalProfiles = 'medical_profiles';
  static const String alerts = 'alerts';
  static const String checkins = 'checkins';
  static const String geofences = 'geofences';
  static const String settings = 'settings';
  static const String logs = 'logs';
}

class FirestoreFields {
  const FirestoreFields._();

  static const String id = 'id';
  static const String name = 'name';
  static const String email = 'email';
  static const String role = 'role';
  static const String guardianIds = 'guardianIds';
  static const String safemateIds = 'safemateIds';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String fcmToken = 'fcmToken';
  static const String batteryLevel = 'batteryLevel';
  static const String lastSeenAt = 'lastSeenAt';
  static const String lastLocationSyncAt = 'lastLocationSyncAt';
  static const String isEmergencyActive = 'isEmergencyActive';
  static const String emergencyContactName = 'emergencyContactName';
  static const String emergencyContactPhone = 'emergencyContactPhone';
  static const String fullName = 'fullName';
  static const String bloodGroup = 'bloodGroup';
  static const String allergies = 'allergies';
  static const String medicalConditions = 'medicalConditions';
  static const String emergencyNotes = 'emergencyNotes';
  static const String userId = 'userId';
  static const String type = 'type';
  static const String status = 'status';
  static const String title = 'title';
  static const String description = 'description';
  static const String timestamp = 'timestamp';
  static const String locationLat = 'locationLat';
  static const String locationLng = 'locationLng';
  static const String audioUrl = 'audioUrl';
  static const String acknowledgedBy = 'acknowledgedBy';
  static const String acknowledgedAt = 'acknowledgedAt';
  static const String canceledByUser = 'canceledByUser';
  static const String resolvedAt = 'resolvedAt';
  static const String zones = 'zones';
  static const String lowBatteryWarningPercent = 'lowBatteryWarningPercent';
  static const String lowBatteryCriticalPercent = 'lowBatteryCriticalPercent';
  static const String checkInEnabled = 'checkInEnabled';
  static const String checkInIntervalMinutes = 'checkInIntervalMinutes';
  static const String autoCheckInEnabled = 'autoCheckInEnabled';
  static const String audioRecordingEnabled = 'audioRecordingEnabled';
  static const String geofencingEnabled = 'geofencingEnabled';
  static const String liveLocationEnabled = 'liveLocationEnabled';
  static const String trustedPlaceModeEnabled = 'trustedPlaceModeEnabled';
  static const String nightModeMonitoringEnabled = 'nightModeMonitoringEnabled';
  static const String sosNotificationsEnabled = 'sosNotificationsEnabled';
  static const String batteryNotificationsEnabled =
      'batteryNotificationsEnabled';
  static const String geofenceNotificationsEnabled =
      'geofenceNotificationsEnabled';
  static const String checkInNotificationsEnabled =
      'checkInNotificationsEnabled';
  static const String emergencyDetectionEnabled = 'emergencyDetectionEnabled';
  static const String fallDetectionEnabled = 'fallDetectionEnabled';
  static const String movementDetectionEnabled = 'movementDetectionEnabled';
  static const String eventType = 'eventType';
  static const String message = 'message';
  static const String metadata = 'metadata';
}

class RealtimeDatabasePaths {
  const RealtimeDatabasePaths._();

  static const String liveLocations = 'live_locations';
}

class StoragePaths {
  const StoragePaths._();

  static const String emergencyAudio = 'emergency_audio';
}
