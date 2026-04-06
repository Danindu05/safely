import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../core/constants/app_constants.dart';
import '../core/services/audio_recording_service.dart';
import '../core/services/battery_service.dart';
import '../core/services/firebase_storage_service.dart';
import '../core/services/local_notifications_service.dart';
import '../core/services/preferences_service.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/retry_helper.dart';
import '../models/activity_log.dart';
import '../models/app_enums.dart';
import '../models/geofence_zone.dart';
import '../models/live_location.dart';
import '../models/safety_alert.dart';
import '../models/safety_checkin.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';
import 'alert_repository.dart';
import 'location_repository.dart';
import 'profile_repository.dart';

class SafetyRuntimeState {
  const SafetyRuntimeState({
    required this.isLiveSharingActive,
    required this.isRecordingActive,
    required this.activeAlertId,
    required this.isTrustedPlaceActive,
    required this.isNightMonitoringActive,
  });

  final bool isLiveSharingActive;
  final bool isRecordingActive;
  final String? activeAlertId;
  final bool isTrustedPlaceActive;
  final bool isNightMonitoringActive;
}

abstract class SafetyRepository {
  Stream<SafetyRuntimeState> get runtimeState;

  Future<SafetyAlert> triggerSos({
    required UserProfile profile,
    required UserSettings settings,
  });

  Future<void> stopEmergency({
    required UserProfile profile,
    required bool falseAlarm,
  });

  Future<void> startManualLiveSharing({required UserProfile profile});

  Future<void> stopManualLiveSharing(String userId);

  Future<void> sendManualCheckIn({
    required UserProfile profile,
    required int? batteryLevel,
  });

  Future<SafetyAlert?> maybeCreateBatteryAlert({
    required UserProfile profile,
    required UserSettings settings,
  });

  Future<SafetyAlert?> evaluateGeofences({
    required UserProfile profile,
    required GeofenceConfig geofenceConfig,
    required UserSettings settings,
  });

  Future<void> evaluateMonitoringModes({
    required UserProfile profile,
    required GeofenceConfig geofenceConfig,
    required UserSettings settings,
  });

  Future<void> dispose();
}

class DefaultSafetyRepository implements SafetyRepository {
  DefaultSafetyRepository({
    required AlertRepository alertRepository,
    required ProfileRepository profileRepository,
    required LocationRepository locationRepository,
    required BatteryService batteryService,
    required AudioRecordingService audioRecordingService,
    required FirebaseStorageService storageService,
    required PreferencesService preferencesService,
    required LocalNotificationsService localNotificationsService,
  }) : _alertRepository = alertRepository,
       _profileRepository = profileRepository,
       _locationRepository = locationRepository,
       _batteryService = batteryService,
       _audioRecordingService = audioRecordingService,
       _storageService = storageService,
       _preferencesService = preferencesService,
       _localNotificationsService = localNotificationsService {
    _emitRuntimeState();
  }

  final AlertRepository _alertRepository;
  final ProfileRepository _profileRepository;
  final LocationRepository _locationRepository;
  final BatteryService _batteryService;
  final AudioRecordingService _audioRecordingService;
  final FirebaseStorageService _storageService;
  final PreferencesService _preferencesService;
  final LocalNotificationsService _localNotificationsService;

  final StreamController<SafetyRuntimeState> _runtimeController =
      StreamController<SafetyRuntimeState>.broadcast();

  StreamSubscription<Position>? _liveLocationSubscription;
  String? _activeAlertId;
  bool _isRecordingActive = false;
  bool _isTrustedPlaceActive = false;
  bool _isNightMonitoringActive = false;

  @override
  Stream<SafetyRuntimeState> get runtimeState => _runtimeController.stream;

  @override
  Future<void> evaluateMonitoringModes({
    required UserProfile profile,
    required GeofenceConfig geofenceConfig,
    required UserSettings settings,
  }) async {
    final bool shouldCheckTrustedPlace =
        settings.trustedPlaceModeEnabled &&
        geofenceConfig.zones.any(
          (GeofenceZone zone) =>
              zone.isEnabled && zone.type == GeofenceType.safe,
        );

    bool isTrustedPlaceActive = false;
    if (shouldCheckTrustedPlace) {
      final Position position = await _locationRepository.getCurrentPosition();
      isTrustedPlaceActive =
          _zoneContainingPoint(
            geofenceConfig: geofenceConfig,
            position: position,
            type: GeofenceType.safe,
          ) !=
          null;
    }

    _isTrustedPlaceActive = isTrustedPlaceActive;
    _isNightMonitoringActive =
        settings.nightModeMonitoringEnabled &&
        _isInNightMonitoringWindow(DateTime.now()) &&
        !_isTrustedPlaceActive;

    if (_isNightMonitoringActive) {
      await _maybeCreateNightMonitoringAlert(
        profile: profile,
        settings: settings,
      );
    }

    _emitRuntimeState();
  }

  @override
  Future<SafetyAlert> triggerSos({
    required UserProfile profile,
    required UserSettings settings,
  }) async {
    final Position position = await _locationRepository.getCurrentPosition();
    final int batteryLevel = await _batteryService.getBatteryLevel();
    final String alertId = DateTime.now().microsecondsSinceEpoch.toString();
    final DateTime now = DateTime.now();

    final SafetyAlert alert = SafetyAlert(
      id: alertId,
      userId: profile.id,
      guardianIds: profile.guardianIds,
      type: AlertType.sos,
      status: AlertStatus.active,
      title: 'SOS activated',
      description: '${profile.name} has triggered an emergency alert.',
      timestamp: now,
      locationLat: position.latitude,
      locationLng: position.longitude,
      batteryLevel: batteryLevel,
      audioUrl: null,
      acknowledgedBy: null,
      acknowledgedAt: null,
      canceledByUser: false,
      resolvedAt: null,
    );

    await _alertRepository.createAlert(alert);
    await _profileRepository.setEmergencyState(
      uid: profile.id,
      isEmergencyActive: true,
    );
    await _profileRepository.updateBatteryLevel(
      uid: profile.id,
      batteryLevel: batteryLevel,
    );
    await _profileRepository.updateLastLocationSync(profile.id, now);
    await _alertRepository.createLog(
      ActivityLog(
        id: '${alertId}_log',
        userId: profile.id,
        eventType: LogEventType.sosTriggered,
        message: 'SOS started and guardians notified.',
        timestamp: now,
        metadata: <String, dynamic>{'alertId': alertId},
      ),
    );

    if (settings.audioRecordingEnabled) {
      try {
        final String? recordingPath = await _audioRecordingService
            .startEmergencyRecording(userId: profile.id, alertId: alertId);
        _isRecordingActive = recordingPath != null;
      } catch (error, stackTrace) {
        AppLogger.error(
          'Emergency audio recording could not start',
          error: error,
          stackTrace: stackTrace,
        );
        _isRecordingActive = false;
      }
    }

    _activeAlertId = alertId;
    await _preferencesService.setActiveAlertId(alertId);
    await _startLiveLocationFeed(
      userId: profile.id,
      guardianIds: profile.guardianIds,
      source: 'sos',
      isEmergency: true,
      initialPosition: position,
    );
    _emitRuntimeState();

    return alert;
  }

  @override
  Future<void> stopEmergency({
    required UserProfile profile,
    required bool falseAlarm,
  }) async {
    final String? alertId = _activeAlertId ?? _preferencesService.activeAlertId;
    if (alertId == null) {
      return;
    }

    final SafetyAlert? alert = await _alertRepository.watchAlert(alertId).first;
    if (alert == null) {
      return;
    }

    String? audioUrl;
    if (_isRecordingActive) {
      _isRecordingActive = false;
      try {
        final String? filePath = await _audioRecordingService.stopRecording();
        if (filePath != null) {
          audioUrl = await RetryHelper.run<String>(
            label: 'upload emergency audio',
            attempts: AppConstants.maxCriticalWriteAttempts,
            operation: () {
              return _storageService.uploadEmergencyAudio(
                userId: profile.id,
                alertId: alertId,
                filePath: filePath,
              );
            },
          );
        }
      } catch (error, stackTrace) {
        AppLogger.error(
          'Emergency audio upload failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    await _alertRepository.updateAlert(
      alert.copyWith(
        status: falseAlarm ? AlertStatus.canceled : AlertStatus.resolved,
        canceledByUser: falseAlarm,
        audioUrl: audioUrl ?? alert.audioUrl,
        resolvedAt: DateTime.now(),
      ),
    );
    await _profileRepository.setEmergencyState(
      uid: profile.id,
      isEmergencyActive: false,
    );
    await _stopLiveSharingInternal(profile.id);
    await _alertRepository.createLog(
      ActivityLog(
        id: '${alertId}_${falseAlarm ? 'cancel' : 'resolve'}',
        userId: profile.id,
        eventType: falseAlarm
            ? LogEventType.sosCanceled
            : LogEventType.sosResolved,
        message: falseAlarm
            ? 'User canceled emergency as a false alarm.'
            : 'Emergency cleared by user.',
        timestamp: DateTime.now(),
        metadata: <String, dynamic>{'alertId': alertId},
      ),
    );

    _activeAlertId = null;
    await _preferencesService.setActiveAlertId(null);
    _emitRuntimeState();
  }

  @override
  Future<void> startManualLiveSharing({required UserProfile profile}) async {
    await _startLiveLocationFeed(
      userId: profile.id,
      guardianIds: profile.guardianIds,
      source: 'manual_share',
      isEmergency: false,
    );
    await _alertRepository.createLog(
      ActivityLog(
        id: 'share_${DateTime.now().microsecondsSinceEpoch}',
        userId: profile.id,
        eventType: LogEventType.liveShareStarted,
        message: 'Manual live location sharing started.',
        timestamp: DateTime.now(),
        metadata: const <String, dynamic>{},
      ),
    );
    _emitRuntimeState();
  }

  @override
  Future<void> stopManualLiveSharing(String userId) async {
    await _stopLiveSharingInternal(userId);
    await _alertRepository.createLog(
      ActivityLog(
        id: 'share_stop_${DateTime.now().microsecondsSinceEpoch}',
        userId: userId,
        eventType: LogEventType.liveShareStopped,
        message: 'Manual live location sharing stopped.',
        timestamp: DateTime.now(),
        metadata: const <String, dynamic>{},
      ),
    );
    _emitRuntimeState();
  }

  @override
  Future<void> sendManualCheckIn({
    required UserProfile profile,
    required int? batteryLevel,
  }) async {
    final Position position = await _locationRepository.getCurrentPosition();
    final String id = DateTime.now().microsecondsSinceEpoch.toString();
    final DateTime now = DateTime.now();

    await _alertRepository.createCheckIn(
      SafetyCheckIn(
        id: id,
        userId: profile.id,
        type: CheckInType.manual,
        timestamp: now,
        batteryLevel: batteryLevel,
        locationLat: position.latitude,
        locationLng: position.longitude,
        status: CheckInStatus.completed,
      ),
    );

    await _alertRepository.createAlert(
      SafetyAlert(
        id: '${id}_alert',
        userId: profile.id,
        guardianIds: profile.guardianIds,
        type: AlertType.manualCheckin,
        status: AlertStatus.resolved,
        title: 'Manual check-in',
        description: '${profile.name} checked in as safe.',
        timestamp: now,
        locationLat: position.latitude,
        locationLng: position.longitude,
        batteryLevel: batteryLevel,
        audioUrl: null,
        acknowledgedBy: null,
        acknowledgedAt: null,
        canceledByUser: false,
        resolvedAt: DateTime.now(),
      ),
    );

    await _alertRepository.createLog(
      ActivityLog(
        id: '${id}_log',
        userId: profile.id,
        eventType: LogEventType.checkIn,
        message: 'Manual safety check-in completed.',
        timestamp: now,
        metadata: <String, dynamic>{'batteryLevel': batteryLevel},
      ),
    );
    await _profileRepository.updateLastLocationSync(profile.id, now);
  }

  @override
  Future<SafetyAlert?> maybeCreateBatteryAlert({
    required UserProfile profile,
    required UserSettings settings,
  }) async {
    final int batteryLevel = await _batteryService.getBatteryLevel();
    await _profileRepository.updateBatteryLevel(
      uid: profile.id,
      batteryLevel: batteryLevel,
    );

    final int? previousLevel = _preferencesService.lastBatteryAlertLevel;
    final int? threshold = batteryLevel <= settings.lowBatteryCriticalPercent
        ? settings.lowBatteryCriticalPercent
        : batteryLevel <= settings.lowBatteryWarningPercent
        ? settings.lowBatteryWarningPercent
        : null;

    if (threshold == null || previousLevel == threshold) {
      if (batteryLevel > settings.lowBatteryWarningPercent) {
        await _preferencesService.setLastBatteryAlertLevel(null);
      }
      return null;
    }

    Position? position = await _locationRepository.getLastKnownPosition();
    if (position == null) {
      try {
        position = await _locationRepository.getCurrentPosition();
      } catch (error, stackTrace) {
        AppLogger.error(
          'Battery alert could not refresh location',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    final SafetyAlert alert = SafetyAlert(
      id: 'battery_${DateTime.now().microsecondsSinceEpoch}',
      userId: profile.id,
      guardianIds: profile.guardianIds,
      type: AlertType.lowBattery,
      status: AlertStatus.active,
      title: batteryLevel <= settings.lowBatteryCriticalPercent
          ? 'Critical battery level'
          : 'Battery running low',
      description: '${profile.name} is at $batteryLevel% battery.',
      timestamp: DateTime.now(),
      locationLat: position?.latitude,
      locationLng: position?.longitude,
      batteryLevel: batteryLevel,
      audioUrl: null,
      acknowledgedBy: null,
      acknowledgedAt: null,
      canceledByUser: false,
      resolvedAt: null,
    );

    await _alertRepository.createAlert(alert);
    await _alertRepository.createLog(
      ActivityLog(
        id: '${alert.id}_log',
        userId: profile.id,
        eventType: LogEventType.lowBatteryTriggered,
        message: 'Low battery alert created at $batteryLevel%.',
        timestamp: DateTime.now(),
        metadata: <String, dynamic>{'batteryLevel': batteryLevel},
      ),
    );
    await _localNotificationsService.showLocalWarning(
      title: alert.title,
      body: 'Guardians can now see this battery warning.',
    );
    await _preferencesService.setLastBatteryAlertLevel(threshold);
    return alert;
  }

  @override
  Future<SafetyAlert?> evaluateGeofences({
    required UserProfile profile,
    required GeofenceConfig geofenceConfig,
    required UserSettings settings,
  }) async {
    if (!settings.geofencingEnabled || geofenceConfig.zones.isEmpty) {
      await _preferencesService.setActiveGeofenceZoneId(null);
      return null;
    }

    final Position position = await _locationRepository.getCurrentPosition();
    final GeofenceZone? unsafeZone = _zoneContainingPoint(
      geofenceConfig: geofenceConfig,
      position: position,
      type: GeofenceType.unsafe,
    );

    if (unsafeZone == null) {
      await _preferencesService.setActiveGeofenceZoneId(null);
      return null;
    }

    if (_preferencesService.activeGeofenceZoneId == unsafeZone.id) {
      return null;
    }

    final DateTime now = DateTime.now();
    final SafetyAlert alert = SafetyAlert(
      id: 'geofence_${now.microsecondsSinceEpoch}',
      userId: profile.id,
      guardianIds: profile.guardianIds,
      type: AlertType.geofence,
      status: AlertStatus.active,
      title: 'Entered unsafe zone',
      description: '${profile.name} entered ${unsafeZone.name}.',
      timestamp: now,
      locationLat: position.latitude,
      locationLng: position.longitude,
      batteryLevel: await _batteryService.getBatteryLevel(),
      audioUrl: null,
      acknowledgedBy: null,
      acknowledgedAt: null,
      canceledByUser: false,
      resolvedAt: null,
    );
    await _alertRepository.createAlert(alert);
    await _alertRepository.createLog(
      ActivityLog(
        id: '${alert.id}_log',
        userId: profile.id,
        eventType: LogEventType.geofenceEntered,
        message: 'Unsafe zone entered: ${unsafeZone.name}.',
        timestamp: now,
        metadata: <String, dynamic>{
          'zoneId': unsafeZone.id,
          'zoneName': unsafeZone.name,
        },
      ),
    );
    await _localNotificationsService.showLocalWarning(
      title: 'Unsafe zone detected',
      body: 'Guardians can see this location warning.',
    );
    await _preferencesService.setActiveGeofenceZoneId(unsafeZone.id);
    return alert;
  }

  GeofenceZone? _zoneContainingPoint({
    required GeofenceConfig geofenceConfig,
    required Position position,
    required GeofenceType type,
  }) {
    for (final GeofenceZone zone in geofenceConfig.zones) {
      if (!zone.isEnabled || zone.type != type) {
        continue;
      }

      final double distance = _locationRepository.distanceBetween(
        startLat: position.latitude,
        startLng: position.longitude,
        endLat: zone.lat,
        endLng: zone.lng,
      );

      if (distance <= zone.radiusMeters) {
        return zone;
      }
    }

    return null;
  }

  bool _isInNightMonitoringWindow(DateTime now) {
    return now.hour >= AppConstants.nightMonitoringStartHour ||
        now.hour < AppConstants.nightMonitoringEndHour;
  }

  Future<void> _maybeCreateNightMonitoringAlert({
    required UserProfile profile,
    required UserSettings settings,
  }) async {
    final DateTime now = DateTime.now();
    final String sessionId = _nightSessionId(now);
    if (_preferencesService.lastNightMonitoringAlertSession == sessionId) {
      return;
    }

    final List<SafetyCheckIn> checkIns = await _alertRepository
        .watchCheckIns(profile.id)
        .first;
    final DateTime referenceTime = checkIns.isNotEmpty
        ? checkIns.first.timestamp
        : (profile.lastSeenAt ?? profile.updatedAt);
    if (now.difference(referenceTime).inMinutes <
        settings.checkInIntervalMinutes) {
      return;
    }

    final Position? lastKnownPosition = await _locationRepository
        .getLastKnownPosition();
    final Position lastPosition =
        lastKnownPosition ?? await _locationRepository.getCurrentPosition();
    final int batteryLevel = await _batteryService.getBatteryLevel();
    final SafetyAlert alert = SafetyAlert(
      id: 'night_${now.microsecondsSinceEpoch}',
      userId: profile.id,
      guardianIds: profile.guardianIds,
      type: AlertType.missedCheckin,
      status: AlertStatus.active,
      title: 'Night monitoring check-in missed',
      description:
          '${profile.name} has not checked in during the active night monitoring window.',
      timestamp: now,
      locationLat: lastPosition.latitude,
      locationLng: lastPosition.longitude,
      batteryLevel: batteryLevel,
      audioUrl: null,
      acknowledgedBy: null,
      acknowledgedAt: null,
      canceledByUser: false,
      resolvedAt: null,
    );

    await _alertRepository.createAlert(alert);
    await _alertRepository.createLog(
      ActivityLog(
        id: '${alert.id}_log',
        userId: profile.id,
        eventType: LogEventType.missedCheckIn,
        message: 'Night monitoring raised a missed check-in alert.',
        timestamp: now,
        metadata: <String, dynamic>{'sessionId': sessionId},
      ),
    );
    await _localNotificationsService.showLocalWarning(
      title: 'Night monitoring needs attention',
      body: 'A missed night check-in alert was sent to guardians.',
    );
    await _preferencesService.setLastNightMonitoringAlertSession(sessionId);
  }

  String _nightSessionId(DateTime now) {
    final DateTime anchorDate = now.hour < AppConstants.nightMonitoringEndHour
        ? now.subtract(const Duration(days: 1))
        : now;
    return '${anchorDate.year.toString().padLeft(4, '0')}-'
        '${anchorDate.month.toString().padLeft(2, '0')}-'
        '${anchorDate.day.toString().padLeft(2, '0')}';
  }

  Future<void> _startLiveLocationFeed({
    required String userId,
    required List<String> guardianIds,
    required String source,
    required bool isEmergency,
    Position? initialPosition,
  }) async {
    await _liveLocationSubscription?.cancel();
    final Position firstPosition =
        initialPosition ?? await _locationRepository.getCurrentPosition();
    await _publishLiveLocation(
      userId: userId,
      guardianIds: guardianIds,
      source: source,
      isEmergency: isEmergency,
      position: firstPosition,
    );

    _liveLocationSubscription = _locationRepository.watchLivePositions().listen(
      (Position position) {
        unawaited(
          _publishLiveLocation(
            userId: userId,
            guardianIds: guardianIds,
            source: source,
            isEmergency: isEmergency,
            position: position,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error(
          'Live location stream failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  Future<void> _stopLiveSharingInternal(String userId) async {
    await _liveLocationSubscription?.cancel();
    _liveLocationSubscription = null;
    await _locationRepository.clearLiveLocation(userId);
  }

  Future<void> _publishLiveLocation({
    required String userId,
    required List<String> guardianIds,
    required String source,
    required bool isEmergency,
    required Position position,
  }) async {
    final DateTime now = DateTime.now();
    await _locationRepository.updateLiveLocation(
      LiveLocation(
        userId: userId,
        guardianIds: guardianIds,
        lat: position.latitude,
        lng: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        updatedAt: now,
        isEmergencyActive: isEmergency,
        source: source,
      ),
    );
    await _profileRepository.updateLastLocationSync(userId, now);
  }

  void _emitRuntimeState() {
    _runtimeController.add(
      SafetyRuntimeState(
        isLiveSharingActive: _liveLocationSubscription != null,
        isRecordingActive: _isRecordingActive,
        activeAlertId: _activeAlertId ?? _preferencesService.activeAlertId,
        isTrustedPlaceActive: _isTrustedPlaceActive,
        isNightMonitoringActive: _isNightMonitoringActive,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _liveLocationSubscription?.cancel();
    await _audioRecordingService.dispose();
    await _runtimeController.close();
  }
}
