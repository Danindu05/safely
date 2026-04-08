import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../core/constants/app_constants.dart';
import '../core/services/audio_recording_service.dart';
import '../core/services/battery_service.dart';
import '../core/services/firebase_storage_service.dart';
import '../core/services/route_service.dart';
import '../core/services/local_notifications_service.dart';
import '../core/services/preferences_service.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/retry_helper.dart';
import '../models/activity_log.dart';
import '../models/app_enums.dart';
import '../models/geofence_zone.dart';
import '../models/live_location.dart';
import '../models/route_geometry.dart';
import '../models/route_tracking_session.dart';
import '../models/safety_alert.dart';
import '../models/safety_checkin.dart';
import '../models/safety_timer_state.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';
import 'alert_repository.dart';
import 'location_repository.dart';
import 'profile_repository.dart';

class SafetyRuntimeState {
  const SafetyRuntimeState({
    required this.isLiveSharingActive,
    required this.isRecordingActive,
    required this.isAudioUploading,
    required this.audioUploadError,
    required this.activeAlertId,
    required this.isTrustedPlaceActive,
    required this.isNightMonitoringActive,
    required this.activeRouteTracking,
    required this.currentRoutePosition,
    required this.safetyTimer,
  });

  final bool isLiveSharingActive;
  final bool isRecordingActive;
  final bool isAudioUploading;
  final String? audioUploadError;
  final String? activeAlertId;
  final bool isTrustedPlaceActive;
  final bool isNightMonitoringActive;
  final RouteTrackingSession? activeRouteTracking;
  final RoutePoint? currentRoutePosition;
  final SafetyTimerState? safetyTimer;
}

abstract class SafetyRepository {
  Stream<SafetyRuntimeState> get runtimeState;

  Future<SafetyAlert> triggerSos({
    required UserProfile profile,
    required UserSettings settings,
    String? autoReason,
  });

  Future<SafetyAlert?> triggerAutoEmergency({
    required UserProfile profile,
    required UserSettings settings,
    required String reason,
    Map<String, Object?> metadata = const <String, Object?>{},
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

  Future<SafetyAlert> createMissedCheckInAlert({
    required UserProfile profile,
    required String description,
    String? title,
    bool showLocalWarning = true,
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

  Future<void> startSafetyTimer({
    required UserProfile profile,
    required Duration duration,
  });

  Future<void> cancelSafetyTimer({String? userId});

  Future<void> evaluateSafetyTimer({
    required UserProfile profile,
    required UserSettings settings,
  });

  Future<void> startRouteTracking({
    required UserProfile profile,
    required double destinationLat,
    required double destinationLng,
  });

  Future<void> stopRouteTracking({required String userId});

  Future<SafetyAlert?> evaluateRouteTracking({required UserProfile profile});

  Future<void> logEmergencyDetection({
    required UserProfile profile,
    required LogEventType eventType,
    required String message,
    required Map<String, Object?> metadata,
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
    required RouteService routeService,
    required PreferencesService preferencesService,
    required LocalNotificationsService localNotificationsService,
  }) : _alertRepository = alertRepository,
       _profileRepository = profileRepository,
       _locationRepository = locationRepository,
       _batteryService = batteryService,
       _audioRecordingService = audioRecordingService,
       _storageService = storageService,
       _routeService = routeService,
       _preferencesService = preferencesService,
       _localNotificationsService = localNotificationsService {
    _restorePersistedRuntimeState();
    _emitRuntimeState();
  }

  final AlertRepository _alertRepository;
  final ProfileRepository _profileRepository;
  final LocationRepository _locationRepository;
  final BatteryService _batteryService;
  final AudioRecordingService _audioRecordingService;
  final FirebaseStorageService _storageService;
  final RouteService _routeService;
  final PreferencesService _preferencesService;
  final LocalNotificationsService _localNotificationsService;

  final StreamController<SafetyRuntimeState> _runtimeController =
      StreamController<SafetyRuntimeState>.broadcast();

  StreamSubscription<Position>? _liveLocationSubscription;
  String? _activeAlertId;
  bool _isRecordingActive = false;
  bool _isAudioUploading = false;
  String? _audioUploadError;
  bool _isTrustedPlaceActive = false;
  bool _isNightMonitoringActive = false;
  SafetyTimerState? _activeSafetyTimer;
  RouteTrackingSession? _activeRouteTracking;
  RoutePoint? _currentRoutePosition;

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
    String? autoReason,
  }) async {
    await cancelSafetyTimer(userId: profile.id);
    await _persistRouteTrackingSession(null);
    _activeRouteTracking = null;
    _audioUploadError = null;

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
      title: autoReason == null ? 'SOS activated' : 'Automatic SOS activated',
      description: autoReason == null
          ? '${profile.name} has triggered an emergency alert.'
          : '${profile.name} may need help. Reason: ${_autoReasonLabel(autoReason)}.',
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
    final Map<String, dynamic> sosLogMetadata = <String, dynamic>{
      'alertId': alertId,
    };
    if (autoReason != null) {
      sosLogMetadata['autoReason'] = autoReason;
    }

    await _alertRepository.createLog(
      ActivityLog(
        id: '${alertId}_log',
        userId: profile.id,
        eventType: LogEventType.sosTriggered,
        message: autoReason == null
            ? 'SOS started and guardians notified.'
            : 'Automatic SOS started from ${_autoReasonLabel(autoReason)}.',
        timestamp: now,
        metadata: sosLogMetadata,
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
  Future<SafetyAlert?> triggerAutoEmergency({
    required UserProfile profile,
    required UserSettings settings,
    required String reason,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    if (profile.isEmergencyActive) {
      AppLogger.warning(
        'Auto emergency ignored because emergency mode is already active.',
      );
      return null;
    }

    final SafetyAlert alert = await triggerSos(
      profile: profile,
      settings: settings,
      autoReason: reason,
    );
    await _alertRepository.createLog(
      ActivityLog(
        id: 'auto_sos_${DateTime.now().microsecondsSinceEpoch}',
        userId: profile.id,
        eventType: LogEventType.emergencyDetectionAutoSos,
        message: 'Automatic SOS triggered: ${_autoReasonLabel(reason)}.',
        timestamp: DateTime.now(),
        metadata: <String, Object?>{
          'alertId': alert.id,
          'reason': reason,
          ...metadata,
        },
      ),
    );
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
    _audioUploadError = null;

    if (_isRecordingActive) {
      _isRecordingActive = false;
      try {
        final String? filePath = await _audioRecordingService.stopRecording();
        if (filePath != null) {
          _isAudioUploading = true;
          _emitRuntimeState();
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
        _audioUploadError = 'Emergency audio could not be uploaded.';
      } finally {
        _isAudioUploading = false;
        _emitRuntimeState();
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
  Future<SafetyAlert> createMissedCheckInAlert({
    required UserProfile profile,
    required String description,
    String? title,
    bool showLocalWarning = true,
  }) {
    return _createMissedCheckInIncident(
      profile: profile,
      title: title ?? 'Missed safety check-in',
      description: description,
      metadata: const <String, dynamic>{'source': 'timed_checkin'},
      localWarningBody:
          'Guardians have been notified about the missed check-in.',
      showLocalWarning: showLocalWarning,
    );
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
    final bool isCritical = batteryLevel <= settings.lowBatteryCriticalPercent;
    final DateTime now = DateTime.now();
    final SafetyAlert alert = SafetyAlert(
      id: 'battery_${now.microsecondsSinceEpoch}',
      userId: profile.id,
      guardianIds: profile.guardianIds,
      type: AlertType.lowBattery,
      status: AlertStatus.active,
      title: isCritical ? 'Critical battery level' : 'Battery running low',
      description: isCritical
          ? 'Battery critical — last location shared'
          : '${profile.name} is at $batteryLevel% battery.',
      timestamp: now,
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
        timestamp: now,
        metadata: <String, dynamic>{'batteryLevel': batteryLevel},
      ),
    );
    if (settings.batteryNotificationsEnabled) {
      await _localNotificationsService.showLocalWarning(
        title: alert.title,
        body: isCritical
            ? 'Last location was shared and emergency mode is starting.'
            : 'Guardians can now see this battery warning.',
      );
    }
    await _preferencesService.setLastBatteryAlertLevel(threshold);

    if (isCritical && !profile.isEmergencyActive) {
      await _activateBatteryEmergency(
        profile: profile,
        batteryLevel: batteryLevel,
        alert: alert,
        position: position,
      );
    }

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
    if (settings.geofenceNotificationsEnabled) {
      await _localNotificationsService.showLocalWarning(
        title: 'Unsafe zone detected',
        body: 'Guardians can see this location warning.',
      );
    }
    await _preferencesService.setActiveGeofenceZoneId(unsafeZone.id);
    return alert;
  }

  @override
  Future<void> startSafetyTimer({
    required UserProfile profile,
    required Duration duration,
  }) async {
    final DateTime now = DateTime.now();
    _activeSafetyTimer = SafetyTimerState(
      durationMinutes: duration.inMinutes,
      startedAt: now,
      endsAt: now.add(duration),
    );
    await _persistSafetyTimerState(_activeSafetyTimer);
    await _alertRepository.createLog(
      ActivityLog(
        id: 'timer_start_${now.microsecondsSinceEpoch}',
        userId: profile.id,
        eventType: LogEventType.safetyTimerStarted,
        message: 'Safety timer started for ${duration.inMinutes} minutes.',
        timestamp: now,
        metadata: <String, dynamic>{'durationMinutes': duration.inMinutes},
      ),
    );
    _emitRuntimeState();
  }

  @override
  Future<void> cancelSafetyTimer({String? userId}) async {
    if (_activeSafetyTimer == null) {
      return;
    }

    final DateTime now = DateTime.now();
    _activeSafetyTimer = null;
    await _persistSafetyTimerState(null);
    if (userId != null) {
      await _alertRepository.createLog(
        ActivityLog(
          id: 'timer_cancel_${now.microsecondsSinceEpoch}',
          userId: userId,
          eventType: LogEventType.safetyTimerCanceled,
          message: 'Safety timer was canceled.',
          timestamp: now,
          metadata: const <String, dynamic>{},
        ),
      );
    }
    _emitRuntimeState();
  }

  @override
  Future<void> evaluateSafetyTimer({
    required UserProfile profile,
    required UserSettings settings,
  }) async {
    final SafetyTimerState? timer = _activeSafetyTimer;
    if (timer == null) {
      return;
    }

    if (timer.endsAt.isAfter(DateTime.now())) {
      _emitRuntimeState();
      return;
    }

    _activeSafetyTimer = null;
    await _persistSafetyTimerState(null);
    _emitRuntimeState();
    await _localNotificationsService.showLocalWarning(
      title: 'Safety timer expired',
      body: 'SOS is being sent now.',
    );

    if (!profile.isEmergencyActive) {
      await triggerSos(profile: profile, settings: settings);
    }
  }

  @override
  Future<void> startRouteTracking({
    required UserProfile profile,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final Position startPosition = await _locationRepository
        .getCurrentPosition();
    final bool startedLiveSharingForRoute = _liveLocationSubscription == null;

    RoutePlan? routePlan;
    try {
      routePlan = await _routeService.fetchRoute(
        startLat: startPosition.latitude,
        startLng: startPosition.longitude,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Route generation failed; falling back to straight-line monitoring',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _currentRoutePosition = RoutePoint(
      lat: startPosition.latitude,
      lng: startPosition.longitude,
    );
    _activeRouteTracking = RouteTrackingSession(
      startLat: startPosition.latitude,
      startLng: startPosition.longitude,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      startedAt: DateTime.now(),
      deviationThresholdMeters: AppConstants.routeDeviationThresholdMeters,
      deviationAlertSent: false,
      startedLiveSharingForRoute: startedLiveSharingForRoute,
      encodedPolyline: routePlan?.encodedPolyline,
      routeBounds: routePlan?.bounds,
      routeSource: routePlan == null ? 'straight_line' : 'osrm',
    );

    await _persistRouteTrackingSession(_activeRouteTracking);
    if (startedLiveSharingForRoute) {
      await _startLiveLocationFeed(
        userId: profile.id,
        guardianIds: profile.guardianIds,
        source: 'route_tracking',
        isEmergency: false,
        initialPosition: startPosition,
      );
    }
    _emitRuntimeState();
  }

  @override
  Future<void> stopRouteTracking({required String userId}) async {
    final RouteTrackingSession? routeTracking = _activeRouteTracking;
    _activeRouteTracking = null;
    _currentRoutePosition = null;
    await _persistRouteTrackingSession(null);
    if (routeTracking?.startedLiveSharingForRoute == true &&
        _activeAlertId == null) {
      await _stopLiveSharingInternal(userId);
    }
    _emitRuntimeState();
  }

  @override
  Future<SafetyAlert?> evaluateRouteTracking({
    required UserProfile profile,
  }) async {
    final RouteTrackingSession? routeTracking = _activeRouteTracking;
    if (routeTracking == null) {
      return null;
    }

    final Position position = await _locationRepository.getCurrentPosition();
    _currentRoutePosition = RoutePoint(
      lat: position.latitude,
      lng: position.longitude,
    );
    if (_liveLocationSubscription == null && _activeAlertId == null) {
      await _startLiveLocationFeed(
        userId: profile.id,
        guardianIds: profile.guardianIds,
        source: 'route_tracking',
        isEmergency: false,
        initialPosition: position,
      );
    }

    final double distanceToDestination = _locationRepository.distanceBetween(
      startLat: position.latitude,
      startLng: position.longitude,
      endLat: routeTracking.destinationLat,
      endLng: routeTracking.destinationLng,
    );

    if (distanceToDestination <= AppConstants.routeCompletionThresholdMeters) {
      await stopRouteTracking(userId: profile.id);
      await _localNotificationsService.showLocalWarning(
        title: 'Journey complete',
        body: 'Route tracking has been turned off.',
      );
      return null;
    }

    final double deviationDistance = _distanceFromRouteMeters(
      routeTracking,
      position,
    );
    if (deviationDistance <= routeTracking.deviationThresholdMeters ||
        routeTracking.deviationAlertSent) {
      return null;
    }

    final int batteryLevel = await _batteryService.getBatteryLevel();
    final DateTime now = DateTime.now();
    final SafetyAlert alert = SafetyAlert(
      id: 'route_${now.microsecondsSinceEpoch}',
      userId: profile.id,
      guardianIds: profile.guardianIds,
      type: AlertType.routeDeviation,
      status: AlertStatus.active,
      title: 'Route deviation detected',
      description: '${profile.name} moved away from the planned journey path.',
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
    await _alertRepository.createLog(
      ActivityLog(
        id: '${alert.id}_log',
        userId: profile.id,
        eventType: LogEventType.routeDeviation,
        message:
            'Route deviation detected at ${deviationDistance.toStringAsFixed(0)} meters from the planned path.',
        timestamp: now,
        metadata: <String, dynamic>{
          'distanceFromRouteMeters': deviationDistance,
          'destinationLat': routeTracking.destinationLat,
          'destinationLng': routeTracking.destinationLng,
        },
      ),
    );
    await _localNotificationsService.showLocalWarning(
      title: 'Route changed',
      body: 'Guardians can now see the route deviation alert.',
    );

    _activeRouteTracking = routeTracking.copyWith(deviationAlertSent: true);
    await _persistRouteTrackingSession(_activeRouteTracking);
    _emitRuntimeState();
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

    await _createMissedCheckInIncident(
      profile: profile,
      title: 'Night monitoring check-in missed',
      description:
          '${profile.name} has not checked in during the active night monitoring window.',
      metadata: <String, dynamic>{'sessionId': sessionId, 'source': 'night'},
      localWarningBody: 'A missed night check-in alert was sent to guardians.',
      showLocalWarning: settings.checkInNotificationsEnabled,
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

  Future<SafetyAlert> _createMissedCheckInIncident({
    required UserProfile profile,
    required String title,
    required String description,
    required Map<String, dynamic> metadata,
    required String localWarningBody,
    required bool showLocalWarning,
  }) async {
    final DateTime now = DateTime.now();
    final Position? lastKnownPosition = await _locationRepository
        .getLastKnownPosition();
    final Position position =
        lastKnownPosition ?? await _locationRepository.getCurrentPosition();
    final int batteryLevel = await _batteryService.getBatteryLevel();
    final String id = 'missed_${now.microsecondsSinceEpoch}';

    await _alertRepository.createCheckIn(
      SafetyCheckIn(
        id: '${id}_checkin',
        userId: profile.id,
        type: CheckInType.missed,
        timestamp: now,
        batteryLevel: batteryLevel,
        locationLat: position.latitude,
        locationLng: position.longitude,
        status: CheckInStatus.missed,
      ),
    );

    final SafetyAlert alert = SafetyAlert(
      id: id,
      userId: profile.id,
      guardianIds: profile.guardianIds,
      type: AlertType.missedCheckin,
      status: AlertStatus.active,
      title: title,
      description: description,
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
    await _alertRepository.createLog(
      ActivityLog(
        id: '${alert.id}_log',
        userId: profile.id,
        eventType: LogEventType.missedCheckIn,
        message: description,
        timestamp: now,
        metadata: metadata,
      ),
    );
    await _profileRepository.updateLastLocationSync(profile.id, now);
    if (showLocalWarning) {
      await _localNotificationsService.showLocalWarning(
        title: title,
        body: localWarningBody,
      );
    }
    return alert;
  }

  Future<void> _activateBatteryEmergency({
    required UserProfile profile,
    required int batteryLevel,
    required SafetyAlert alert,
    required Position? position,
  }) async {
    final DateTime now = DateTime.now();
    Position? livePosition = position;
    livePosition ??= await _locationRepository.getLastKnownPosition();
    if (livePosition == null) {
      try {
        livePosition = await _locationRepository.getCurrentPosition();
      } catch (error, stackTrace) {
        AppLogger.error(
          'Critical battery could not refresh location for emergency mode',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    await _profileRepository.setEmergencyState(
      uid: profile.id,
      isEmergencyActive: true,
    );
    _activeAlertId = alert.id;
    await _preferencesService.setActiveAlertId(alert.id);
    if (livePosition != null) {
      await _startLiveLocationFeed(
        userId: profile.id,
        guardianIds: profile.guardianIds,
        source: 'low_battery',
        isEmergency: true,
        initialPosition: livePosition,
      );
    }
    await _alertRepository.createLog(
      ActivityLog(
        id: '${alert.id}_battery_emergency',
        userId: profile.id,
        eventType: LogEventType.batteryEmergencyStarted,
        message: 'Critical battery triggered emergency mode and live sharing.',
        timestamp: now,
        metadata: <String, dynamic>{'batteryLevel': batteryLevel},
      ),
    );
    _emitRuntimeState();
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

  void _restorePersistedRuntimeState() {
    _activeAlertId = _preferencesService.activeAlertId;
    _activeSafetyTimer = _decodeSafetyTimerState(
      _preferencesService.safetyTimerStateJson,
    );
    _activeRouteTracking = _decodeRouteTrackingState(
      _preferencesService.routeTrackingStateJson,
    );
    if (_activeRouteTracking != null) {
      _currentRoutePosition = RoutePoint(
        lat: _activeRouteTracking!.startLat,
        lng: _activeRouteTracking!.startLng,
      );
    }
  }

  SafetyTimerState? _decodeSafetyTimerState(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    try {
      final Object? decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic>) {
        return SafetyTimerState.fromMap(decoded);
      }
      if (decoded is Map) {
        return SafetyTimerState.fromMap(decoded.cast<String, dynamic>());
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to decode persisted safety timer state',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  RouteTrackingSession? _decodeRouteTrackingState(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    try {
      final Object? decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic>) {
        return RouteTrackingSession.fromMap(decoded);
      }
      if (decoded is Map) {
        return RouteTrackingSession.fromMap(decoded.cast<String, dynamic>());
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to decode persisted route tracking state',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  Future<void> _persistSafetyTimerState(SafetyTimerState? timer) {
    return _preferencesService.setSafetyTimerStateJson(
      timer == null ? null : jsonEncode(timer.toMap()),
    );
  }

  Future<void> _persistRouteTrackingSession(RouteTrackingSession? session) {
    return _preferencesService.setRouteTrackingStateJson(
      session == null ? null : jsonEncode(session.toMap()),
    );
  }

  double _distanceFromRouteMeters(
    RouteTrackingSession session,
    Position currentPosition,
  ) {
    final String? encodedPolyline = session.encodedPolyline;
    if (encodedPolyline != null && encodedPolyline.isNotEmpty) {
      try {
        final List<RoutePoint> routePoints = _routeService.decodePolyline(
          encodedPolyline,
        );
        if (routePoints.length >= 2) {
          return _distanceFromPolylineMeters(routePoints, currentPosition);
        }
      } catch (error, stackTrace) {
        AppLogger.error(
          'Route polyline decode failed; falling back to straight-line distance',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return _distanceFromRouteLineMeters(session, currentPosition);
  }

  double _distanceFromPolylineMeters(
    List<RoutePoint> routePoints,
    Position currentPosition,
  ) {
    double? nearestDistance;
    for (int index = 0; index < routePoints.length - 1; index++) {
      final double distance = _distanceFromSegmentMeters(
        startLat: routePoints[index].lat,
        startLng: routePoints[index].lng,
        endLat: routePoints[index + 1].lat,
        endLng: routePoints[index + 1].lng,
        currentLat: currentPosition.latitude,
        currentLng: currentPosition.longitude,
      );
      nearestDistance = nearestDistance == null
          ? distance
          : math.min(nearestDistance, distance);
    }
    return nearestDistance ?? double.infinity;
  }

  double _distanceFromRouteLineMeters(
    RouteTrackingSession session,
    Position currentPosition,
  ) {
    return _distanceFromSegmentMeters(
      startLat: session.startLat,
      startLng: session.startLng,
      endLat: session.destinationLat,
      endLng: session.destinationLng,
      currentLat: currentPosition.latitude,
      currentLng: currentPosition.longitude,
    );
  }

  double _distanceFromSegmentMeters({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required double currentLat,
    required double currentLng,
  }) {
    const double metersPerDegreeLat = 111320;
    final double midLatRadians = ((startLat + endLat) / 2) * (math.pi / 180);
    final double metersPerDegreeLng =
        metersPerDegreeLat * math.cos(midLatRadians);

    final _Point start = _Point(0, 0);
    final _Point end = _Point(
      (endLng - startLng) * metersPerDegreeLng,
      (endLat - startLat) * metersPerDegreeLat,
    );
    final _Point current = _Point(
      (currentLng - startLng) * metersPerDegreeLng,
      (currentLat - startLat) * metersPerDegreeLat,
    );

    final double lineLengthSquared = end.x * end.x + end.y * end.y;
    if (lineLengthSquared == 0) {
      return math.sqrt(current.x * current.x + current.y * current.y);
    }

    final double projection =
        ((current.x - start.x) * (end.x - start.x) +
            (current.y - start.y) * (end.y - start.y)) /
        lineLengthSquared;
    final double clampedProjection = projection.clamp(0, 1).toDouble();
    final double nearestX = start.x + (end.x - start.x) * clampedProjection;
    final double nearestY = start.y + (end.y - start.y) * clampedProjection;
    final double dx = current.x - nearestX;
    final double dy = current.y - nearestY;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  Future<void> logEmergencyDetection({
    required UserProfile profile,
    required LogEventType eventType,
    required String message,
    required Map<String, Object?> metadata,
  }) {
    return _alertRepository.createLog(
      ActivityLog(
        id: 'detection_${DateTime.now().microsecondsSinceEpoch}',
        userId: profile.id,
        eventType: eventType,
        message: message,
        timestamp: DateTime.now(),
        metadata: metadata,
      ),
    );
  }

  String _autoReasonLabel(String reason) {
    return switch (reason) {
      'fall_detected' => 'possible fall detected',
      'abnormal_movement' => 'unusual movement detected',
      'no_response' => 'no response to safety confirmation',
      'panic_trigger' => 'manual panic trigger',
      _ => reason.replaceAll('_', ' '),
    };
  }

  void _emitRuntimeState() {
    _runtimeController.add(
      SafetyRuntimeState(
        isLiveSharingActive: _liveLocationSubscription != null,
        isRecordingActive: _isRecordingActive,
        isAudioUploading: _isAudioUploading,
        audioUploadError: _audioUploadError,
        activeAlertId: _activeAlertId ?? _preferencesService.activeAlertId,
        isTrustedPlaceActive: _isTrustedPlaceActive,
        isNightMonitoringActive: _isNightMonitoringActive,
        activeRouteTracking: _activeRouteTracking,
        currentRoutePosition: _currentRoutePosition,
        safetyTimer: _activeSafetyTimer,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _liveLocationSubscription?.cancel();
    await _audioRecordingService.dispose();
    _routeService.dispose();
    await _runtimeController.close();
  }
}

class _Point {
  const _Point(this.x, this.y);

  final double x;
  final double y;
}
