import 'package:flutter/material.dart';

import '../theme/app_tone.dart';
import '../../models/app_enums.dart';

class EventUiMapper {
  const EventUiMapper._();

  static IconData iconForAlertType(AlertType type) {
    return switch (type) {
      AlertType.sos => Icons.sos_rounded,
      AlertType.lowBattery => Icons.battery_alert_rounded,
      AlertType.geofence => Icons.gpp_bad_outlined,
      AlertType.missedCheckin => Icons.schedule_send_outlined,
      AlertType.manualCheckin => Icons.check_circle_outline,
      AlertType.routeDeviation => Icons.alt_route,
    };
  }

  static AppTone toneForAlertType(AlertType type) {
    return switch (type) {
      AlertType.sos => AppTone.danger,
      AlertType.lowBattery => AppTone.warning,
      AlertType.geofence => AppTone.warning,
      AlertType.missedCheckin => AppTone.warning,
      AlertType.manualCheckin => AppTone.safe,
      AlertType.routeDeviation => AppTone.info,
    };
  }

  static AppTone toneForAlertStatus(AlertStatus status) {
    return switch (status) {
      AlertStatus.active => AppTone.danger,
      AlertStatus.acknowledged => AppTone.info,
      AlertStatus.canceled => AppTone.neutral,
      AlertStatus.resolved => AppTone.safe,
    };
  }

  static IconData iconForCheckInType(CheckInType type) {
    return switch (type) {
      CheckInType.manual => Icons.check_circle_outline,
      CheckInType.auto => Icons.autorenew,
      CheckInType.missed => Icons.error_outline,
    };
  }

  static AppTone toneForCheckInType(CheckInType type) {
    return switch (type) {
      CheckInType.manual => AppTone.safe,
      CheckInType.auto => AppTone.info,
      CheckInType.missed => AppTone.warning,
    };
  }

  static IconData iconForLogEvent(LogEventType type) {
    return switch (type) {
      LogEventType.sosTriggered => Icons.sos_rounded,
      LogEventType.sosCanceled => Icons.undo,
      LogEventType.sosResolved => Icons.task_alt,
      LogEventType.lowBatteryTriggered => Icons.battery_alert_outlined,
      LogEventType.missedCheckIn => Icons.watch_later_outlined,
      LogEventType.checkIn => Icons.check_circle_outline,
      LogEventType.liveShareStarted => Icons.share_location_outlined,
      LogEventType.liveShareStopped => Icons.location_off_outlined,
      LogEventType.geofenceEntered => Icons.gpp_bad_outlined,
      LogEventType.routeDeviation => Icons.alt_route,
      LogEventType.safetyTimerStarted => Icons.timer_outlined,
      LogEventType.safetyTimerCanceled => Icons.timer_off_outlined,
      LogEventType.batteryEmergencyStarted => Icons.battery_charging_full,
      LogEventType.emergencyDetectionTriggered =>
        Icons.health_and_safety_outlined,
      LogEventType.emergencyDetectionCanceled => Icons.check_circle_outline,
      LogEventType.emergencyDetectionAutoSos => Icons.warning_amber_rounded,
      LogEventType.guardianLinked => Icons.groups_2_outlined,
      LogEventType.guardianRemoved => Icons.person_remove_outlined,
    };
  }

  static AppTone toneForLogEvent(LogEventType type) {
    return switch (type) {
      LogEventType.sosTriggered ||
      LogEventType.batteryEmergencyStarted ||
      LogEventType.emergencyDetectionAutoSos => AppTone.danger,
      LogEventType.lowBatteryTriggered ||
      LogEventType.missedCheckIn ||
      LogEventType.geofenceEntered => AppTone.warning,
      LogEventType.routeDeviation ||
      LogEventType.liveShareStarted ||
      LogEventType.safetyTimerStarted ||
      LogEventType.emergencyDetectionTriggered => AppTone.info,
      LogEventType.checkIn ||
      LogEventType.sosResolved ||
      LogEventType.emergencyDetectionCanceled ||
      LogEventType.guardianLinked => AppTone.safe,
      LogEventType.sosCanceled ||
      LogEventType.liveShareStopped ||
      LogEventType.safetyTimerCanceled ||
      LogEventType.guardianRemoved => AppTone.neutral,
    };
  }
}
