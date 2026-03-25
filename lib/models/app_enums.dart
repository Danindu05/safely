enum UserRole { safemate, guardian }

UserRole? userRoleFromValue(String? value) {
  switch (value) {
    case 'safemate':
      return UserRole.safemate;
    case 'guardian':
      return UserRole.guardian;
    default:
      return null;
  }
}

extension UserRoleX on UserRole {
  String get value => name;

  String get label => switch (this) {
    UserRole.safemate => 'Safemate',
    UserRole.guardian => 'Guardian',
  };
}

enum AlertType { sos, lowBattery, geofence, missedCheckin, manualCheckin }

AlertType? alertTypeFromValue(String? value) {
  switch (value) {
    case 'sos':
      return AlertType.sos;
    case 'low_battery':
      return AlertType.lowBattery;
    case 'geofence':
      return AlertType.geofence;
    case 'missed_checkin':
      return AlertType.missedCheckin;
    case 'manual_checkin':
      return AlertType.manualCheckin;
    default:
      return null;
  }
}

extension AlertTypeX on AlertType {
  String get value => switch (this) {
    AlertType.sos => 'sos',
    AlertType.lowBattery => 'low_battery',
    AlertType.geofence => 'geofence',
    AlertType.missedCheckin => 'missed_checkin',
    AlertType.manualCheckin => 'manual_checkin',
  };

  String get label => switch (this) {
    AlertType.sos => 'SOS',
    AlertType.lowBattery => 'Low battery',
    AlertType.geofence => 'Geofence',
    AlertType.missedCheckin => 'Missed check-in',
    AlertType.manualCheckin => 'Check-in',
  };
}

enum AlertStatus { active, acknowledged, canceled, resolved }

AlertStatus? alertStatusFromValue(String? value) {
  switch (value) {
    case 'active':
      return AlertStatus.active;
    case 'acknowledged':
      return AlertStatus.acknowledged;
    case 'canceled':
      return AlertStatus.canceled;
    case 'resolved':
      return AlertStatus.resolved;
    default:
      return null;
  }
}

extension AlertStatusX on AlertStatus {
  String get value => name;

  String get label => switch (this) {
    AlertStatus.active => 'Active',
    AlertStatus.acknowledged => 'Acknowledged',
    AlertStatus.canceled => 'Canceled',
    AlertStatus.resolved => 'Resolved',
  };
}

enum CheckInType { manual, auto, missed }

CheckInType? checkInTypeFromValue(String? value) {
  switch (value) {
    case 'manual':
      return CheckInType.manual;
    case 'auto':
      return CheckInType.auto;
    case 'missed':
      return CheckInType.missed;
    default:
      return null;
  }
}

extension CheckInTypeX on CheckInType {
  String get value => name;

  String get label => switch (this) {
    CheckInType.manual => 'Manual',
    CheckInType.auto => 'Auto',
    CheckInType.missed => 'Missed',
  };
}

enum CheckInStatus { completed, pending, missed }

CheckInStatus? checkInStatusFromValue(String? value) {
  switch (value) {
    case 'completed':
      return CheckInStatus.completed;
    case 'pending':
      return CheckInStatus.pending;
    case 'missed':
      return CheckInStatus.missed;
    default:
      return null;
  }
}

extension CheckInStatusX on CheckInStatus {
  String get value => name;
}

enum GeofenceType { unsafe, safe }

GeofenceType? geofenceTypeFromValue(String? value) {
  switch (value) {
    case 'unsafe':
      return GeofenceType.unsafe;
    case 'safe':
      return GeofenceType.safe;
    default:
      return null;
  }
}

extension GeofenceTypeX on GeofenceType {
  String get value => name;

  String get label => switch (this) {
    GeofenceType.unsafe => 'Unsafe zone',
    GeofenceType.safe => 'Safe zone',
  };
}

enum LogEventType {
  sosTriggered,
  sosCanceled,
  sosResolved,
  lowBatteryTriggered,
  missedCheckIn,
  checkIn,
  liveShareStarted,
  liveShareStopped,
  geofenceEntered,
  guardianLinked,
  guardianRemoved,
}

LogEventType? logEventTypeFromValue(String? value) {
  switch (value) {
    case 'sos_triggered':
      return LogEventType.sosTriggered;
    case 'sos_canceled':
      return LogEventType.sosCanceled;
    case 'sos_resolved':
      return LogEventType.sosResolved;
    case 'low_battery_triggered':
      return LogEventType.lowBatteryTriggered;
    case 'missed_checkin':
      return LogEventType.missedCheckIn;
    case 'check_in':
      return LogEventType.checkIn;
    case 'live_share_started':
      return LogEventType.liveShareStarted;
    case 'live_share_stopped':
      return LogEventType.liveShareStopped;
    case 'geofence_entered':
      return LogEventType.geofenceEntered;
    case 'guardian_linked':
      return LogEventType.guardianLinked;
    case 'guardian_removed':
      return LogEventType.guardianRemoved;
    default:
      return null;
  }
}

extension LogEventTypeX on LogEventType {
  String get value => switch (this) {
    LogEventType.sosTriggered => 'sos_triggered',
    LogEventType.sosCanceled => 'sos_canceled',
    LogEventType.sosResolved => 'sos_resolved',
    LogEventType.lowBatteryTriggered => 'low_battery_triggered',
    LogEventType.missedCheckIn => 'missed_checkin',
    LogEventType.checkIn => 'check_in',
    LogEventType.liveShareStarted => 'live_share_started',
    LogEventType.liveShareStopped => 'live_share_stopped',
    LogEventType.geofenceEntered => 'geofence_entered',
    LogEventType.guardianLinked => 'guardian_linked',
    LogEventType.guardianRemoved => 'guardian_removed',
  };

  String get label => switch (this) {
    LogEventType.sosTriggered => 'SOS started',
    LogEventType.sosCanceled => 'False alarm canceled',
    LogEventType.sosResolved => 'Emergency cleared',
    LogEventType.lowBatteryTriggered => 'Low battery',
    LogEventType.missedCheckIn => 'Missed check-in',
    LogEventType.checkIn => 'Check-in',
    LogEventType.liveShareStarted => 'Live sharing started',
    LogEventType.liveShareStopped => 'Live sharing stopped',
    LogEventType.geofenceEntered => 'Geofence event',
    LogEventType.guardianLinked => 'Guardian linked',
    LogEventType.guardianRemoved => 'Guardian removed',
  };
}

enum AppPermissionState { granted, denied, permanentlyDenied }
