import 'dart:async';
import 'dart:convert';

import '../core/constants/app_constants.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/emergency_detection_service.dart';
import '../core/services/geofence_service.dart';
import '../core/utils/app_logger.dart';
import '../models/app_enums.dart';
import '../models/geofence_zone.dart';
import '../models/safety_checkin.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';
import '../repositories/alert_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/safety_repository.dart';
import 'base_viewmodel.dart';

class SafemateShellViewModel extends BaseViewModel {
  SafemateShellViewModel({
    required ProfileRepository profileRepository,
    required AlertRepository alertRepository,
    required SafetyRepository safetyRepository,
    required ConnectivityService connectivityService,
    required GeofenceRegistrationService geofenceRegistrationService,
    required EmergencyDetectionService emergencyDetectionService,
    required UserProfile initialUser,
  }) : _profileRepository = profileRepository,
       _alertRepository = alertRepository,
       _safetyRepository = safetyRepository,
       _connectivityService = connectivityService,
       _geofenceRegistrationService = geofenceRegistrationService,
       _emergencyDetectionService = emergencyDetectionService,
       _userId = initialUser.id,
       _currentUser = initialUser,
       _settings = UserSettings.defaults(initialUser.id) {
    _bind();
  }

  final ProfileRepository _profileRepository;
  final AlertRepository _alertRepository;
  final SafetyRepository _safetyRepository;
  final ConnectivityService _connectivityService;
  final GeofenceRegistrationService _geofenceRegistrationService;
  final EmergencyDetectionService _emergencyDetectionService;
  final String _userId;

  StreamSubscription<UserProfile?>? _userSubscription;
  StreamSubscription<UserSettings?>? _settingsSubscription;
  StreamSubscription<GeofenceConfig?>? _geofenceSubscription;
  StreamSubscription<List<SafetyCheckIn>>? _checkInSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<SafetyRuntimeState>? _runtimeSubscription;
  StreamSubscription<EmergencyEvent>? _emergencyDetectionSubscription;
  Timer? _monitorTimer;
  Timer? _heartbeatTimer;
  Timer? _emergencyConfirmationTimer;

  UserProfile _currentUser;
  UserSettings? _settings;
  GeofenceConfig? _geofenceConfig;
  bool _isOnline = true;
  DateTime? _lastCheckInReferenceAt;
  DateTime? _checkInPromptStartedAt;
  DateTime? _checkInPromptDeadline;
  DateTime? _lastRouteEvaluationAt;
  bool _handlingMissedCheckIn = false;
  bool _autoEmergencyInProgress = false;
  String? _lastOsGeofenceSignature;
  int _panicTapCount = 0;
  DateTime? _lastPanicTapAt;
  EmergencyConfirmationState? _emergencyConfirmation;
  SafetyRuntimeState _runtimeState = const SafetyRuntimeState(
    isLiveSharingActive: false,
    isRecordingActive: false,
    isAudioUploading: false,
    audioUploadError: null,
    activeAlertId: null,
    isTrustedPlaceActive: false,
    isNightMonitoringActive: false,
    activeRouteTracking: null,
    currentRoutePosition: null,
    safetyTimer: null,
  );

  UserProfile get currentUser => _currentUser;
  UserSettings? get settings => _settings;
  GeofenceConfig? get geofenceConfig => _geofenceConfig;
  bool get isOnline => _isOnline;
  SafetyRuntimeState get runtimeState => _runtimeState;
  bool get shouldShowCheckInPrompt => _checkInPromptDeadline != null;
  EmergencyConfirmationState? get emergencyConfirmation =>
      _emergencyConfirmation;

  Duration? get checkInPromptRemaining {
    final DateTime? deadline = _checkInPromptDeadline;
    if (deadline == null) {
      return null;
    }

    final Duration remaining = deadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  DateTime? get nextCheckInDueAt {
    final UserSettings settings = _settings ?? UserSettings.defaults(_userId);
    if (!settings.checkInEnabled) {
      return null;
    }

    final DateTime referenceTime =
        _lastCheckInReferenceAt ??
        _currentUser.lastSeenAt ??
        _currentUser.updatedAt;
    return referenceTime.add(
      Duration(minutes: settings.checkInIntervalMinutes),
    );
  }

  void _bind() {
    _userSubscription = _profileRepository.watchUserProfile(_userId).listen((
      UserProfile? user,
    ) {
      if (user != null) {
        _currentUser = user;
        _lastCheckInReferenceAt ??= user.lastSeenAt ?? user.updatedAt;
        AppLogger.info('Safemate profile loaded for ${user.id}');
        unawaited(_syncEmergencyDetection());
        notifyListeners();
      }
    });
    _settingsSubscription = _profileRepository.watchSettings(_userId).listen((
      UserSettings? settings,
    ) {
      _settings = settings ?? UserSettings.defaults(_userId);
      AppLogger.info('Safemate settings loaded for $_userId');
      unawaited(_syncOsGeofences());
      unawaited(_syncEmergencyDetection());
      notifyListeners();
    });
    _geofenceSubscription = _profileRepository.watchGeofences(_userId).listen((
      GeofenceConfig? config,
    ) {
      _geofenceConfig = config;
      unawaited(_syncOsGeofences());
      notifyListeners();
    });
    _checkInSubscription = _alertRepository.watchCheckIns(_userId).listen((
      List<SafetyCheckIn> checkIns,
    ) {
      if (checkIns.isNotEmpty) {
        final DateTime latestCheckInAt = checkIns.first.timestamp;
        if (_lastCheckInReferenceAt == null ||
            latestCheckInAt.isAfter(_lastCheckInReferenceAt!)) {
          _lastCheckInReferenceAt = latestCheckInAt;
        }

        final DateTime? promptStartedAt = _checkInPromptStartedAt;
        if (promptStartedAt != null &&
            latestCheckInAt.isAfter(
              promptStartedAt.subtract(const Duration(seconds: 1)),
            )) {
          _clearCheckInPrompt();
        }
      }
      notifyListeners();
    });
    _connectivitySubscription = _connectivityService.onStatusChanged().listen((
      bool online,
    ) {
      _isOnline = online;
      notifyListeners();
    });
    _runtimeSubscription = _safetyRepository.runtimeState.listen((
      SafetyRuntimeState state,
    ) {
      _runtimeState = state;
      if (state.activeRouteTracking == null) {
        _lastRouteEvaluationAt = null;
      }
      notifyListeners();
    });
    _emergencyDetectionSubscription = _emergencyDetectionService.events.listen(
      (EmergencyEvent event) =>
          unawaited(_handleEmergencyDetectionEvent(event)),
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error(
          'Emergency detection stream failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    _monitorTimer = Timer.periodic(
      const Duration(minutes: AppConstants.backgroundMonitorIntervalMinutes),
      (_) => unawaited(_runMonitors()),
    );
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: AppConstants.runtimeHeartbeatIntervalSeconds),
      (_) => unawaited(_runHeartbeat()),
    );
    unawaited(_runMonitors());
    unawaited(_runHeartbeat());
    unawaited(_syncEmergencyDetection());
  }

  Future<void> _syncEmergencyDetection() async {
    final UserSettings settings = _settings ?? UserSettings.defaults(_userId);
    if (_currentUser.isEmergencyActive) {
      await _emergencyDetectionService.stop();
      _clearEmergencyConfirmation();
      return;
    }

    await _emergencyDetectionService.updateConfig(
      EmergencyDetectionConfig(
        enabled: settings.emergencyDetectionEnabled,
        fallDetectionEnabled: settings.fallDetectionEnabled,
        movementDetectionEnabled: settings.movementDetectionEnabled,
      ),
    );
  }

  Future<void> _syncOsGeofences() async {
    final UserSettings settings = _settings ?? UserSettings.defaults(_userId);
    final GeofenceConfig config =
        _geofenceConfig ?? GeofenceConfig.empty(_userId);
    final Iterable<GeofenceZone> enabledZones = config.zones.where(
      (GeofenceZone zone) => zone.isEnabled,
    );
    final String signature = settings.geofencingEnabled
        ? jsonEncode(<String, Object?>{
            'enabled': true,
            'zones': enabledZones
                .map((GeofenceZone zone) => zone.toMap())
                .toList(growable: false),
          })
        : 'disabled';

    if (_lastOsGeofenceSignature == signature) {
      return;
    }
    _lastOsGeofenceSignature = signature;

    if (!settings.geofencingEnabled || enabledZones.isEmpty) {
      await _geofenceRegistrationService.clearGeofences();
      return;
    }

    final bool registered = await _geofenceRegistrationService
        .registerGeofences(
          config,
          geofenceNotificationsEnabled: settings.geofenceNotificationsEnabled,
        );
    if (!registered) {
      AppLogger.warning(
        'OS geofencing unavailable; Safely will use app-side geofence checks.',
      );
    }
  }

  Future<void> _handleEmergencyDetectionEvent(EmergencyEvent event) async {
    final UserSettings settings = _settings ?? UserSettings.defaults(_userId);
    if (_currentUser.isEmergencyActive ||
        _emergencyConfirmation != null ||
        !settings.emergencyDetectionEnabled ||
        !_detectionTypeEnabled(event, settings)) {
      return;
    }

    AppLogger.warning(
      'Emergency detection pending confirmation: ${event.type.value}',
    );
    await _safetyRepository.logEmergencyDetection(
      profile: _currentUser,
      eventType: LogEventType.emergencyDetectionTriggered,
      message: 'Unusual activity detected: ${event.type.label}.',
      metadata: <String, Object?>{
        'type': event.type.value,
        'confidenceLevel': event.confidenceLevel,
        ...event.details,
      },
    );

    final DateTime now = DateTime.now();
    _emergencyConfirmation = EmergencyConfirmationState(
      event: event,
      startedAt: now,
      deadline: now.add(
        const Duration(
          seconds: AppConstants.emergencyDetectionConfirmationSeconds,
        ),
      ),
    );
    _emergencyConfirmationTimer?.cancel();
    _emergencyConfirmationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_tickEmergencyConfirmation()),
    );
    notifyListeners();
  }

  bool _detectionTypeEnabled(EmergencyEvent event, UserSettings settings) {
    return switch (event.type) {
      EmergencyEventType.fallDetected ||
      EmergencyEventType.phoneDrop => settings.fallDetectionEnabled,
      EmergencyEventType.abnormalMovement ||
      EmergencyEventType.suddenStop => settings.movementDetectionEnabled,
    };
  }

  Future<void> _tickEmergencyConfirmation() async {
    final EmergencyConfirmationState? confirmation = _emergencyConfirmation;
    if (confirmation == null) {
      _emergencyConfirmationTimer?.cancel();
      _emergencyConfirmationTimer = null;
      return;
    }

    if (DateTime.now().isBefore(confirmation.deadline)) {
      notifyListeners();
      return;
    }

    await _triggerAutoEmergencyFromDetection(
      confirmation,
      reason: 'no_response',
    );
  }

  Future<void> confirmEmergencyDetectionSafe() async {
    final EmergencyConfirmationState? confirmation = _emergencyConfirmation;
    if (confirmation == null) {
      return;
    }

    _clearEmergencyConfirmation();
    await _safetyRepository.logEmergencyDetection(
      profile: _currentUser,
      eventType: LogEventType.emergencyDetectionCanceled,
      message: 'User confirmed safe after ${confirmation.event.type.label}.',
      metadata: <String, Object?>{
        'type': confirmation.event.type.value,
        'confidenceLevel': confirmation.event.confidenceLevel,
        'action': 'user_safe',
      },
    );
    setInfo('Safety confirmation cleared.');
  }

  Future<void> sendHelpFromEmergencyDetection() async {
    final EmergencyConfirmationState? confirmation = _emergencyConfirmation;
    if (confirmation == null) {
      return;
    }

    await _triggerAutoEmergencyFromDetection(
      confirmation,
      reason: confirmation.event.type.sosReason,
    );
  }

  Future<void> _triggerAutoEmergencyFromDetection(
    EmergencyConfirmationState confirmation, {
    required String reason,
  }) async {
    if (_autoEmergencyInProgress) {
      return;
    }

    _autoEmergencyInProgress = true;
    _clearEmergencyConfirmation();
    try {
      await _safetyRepository.triggerAutoEmergency(
        profile: _currentUser,
        settings: _settings ?? UserSettings.defaults(_userId),
        reason: reason,
        metadata: <String, Object?>{
          'detectedType': confirmation.event.type.value,
          'confidenceLevel': confirmation.event.confidenceLevel,
          ...confirmation.event.details,
        },
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Automatic emergency trigger failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error);
    } finally {
      _autoEmergencyInProgress = false;
      notifyListeners();
    }
  }

  void _clearEmergencyConfirmation() {
    _emergencyConfirmationTimer?.cancel();
    _emergencyConfirmationTimer = null;
    _emergencyConfirmation = null;
    notifyListeners();
  }

  Future<void> _runMonitors() async {
    final UserSettings settings = _settings ?? UserSettings.defaults(_userId);

    try {
      await _profileRepository.updateLastSeen(_userId);
      final GeofenceConfig geofenceConfig =
          _geofenceConfig ?? GeofenceConfig.empty(_userId);
      await _safetyRepository.evaluateMonitoringModes(
        profile: _currentUser,
        geofenceConfig: geofenceConfig,
        settings: settings,
      );
      await _safetyRepository.maybeCreateBatteryAlert(
        profile: _currentUser,
        settings: settings,
      );
      await _safetyRepository.evaluateGeofences(
        profile: _currentUser,
        geofenceConfig: geofenceConfig,
        settings: settings,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Background safety monitors failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error);
    }
  }

  Future<void> _runHeartbeat() async {
    final UserSettings settings = _settings ?? UserSettings.defaults(_userId);
    final DateTime now = DateTime.now();

    try {
      await _safetyRepository.evaluateSafetyTimer(
        profile: _currentUser,
        settings: settings,
      );

      if (_runtimeState.activeRouteTracking != null &&
          (_lastRouteEvaluationAt == null ||
              now.difference(_lastRouteEvaluationAt!).inSeconds >=
                  AppConstants.routeEvaluationIntervalSeconds)) {
        _lastRouteEvaluationAt = now;
        await _safetyRepository.evaluateRouteTracking(profile: _currentUser);
      }

      await _updateCheckInPrompt(now, settings);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Safety heartbeat failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _updateCheckInPrompt(DateTime now, UserSettings settings) async {
    if (!settings.checkInEnabled || _currentUser.isEmergencyActive) {
      if (_checkInPromptDeadline != null) {
        _clearCheckInPrompt();
      }
      return;
    }

    if (_checkInPromptDeadline != null) {
      if (now.isAfter(_checkInPromptDeadline!)) {
        await _handleMissedCheckIn();
      } else {
        notifyListeners();
      }
      return;
    }

    final DateTime dueAt =
        nextCheckInDueAt ??
        now.add(Duration(minutes: settings.checkInIntervalMinutes));
    if (!now.isBefore(dueAt)) {
      _checkInPromptStartedAt = now;
      _checkInPromptDeadline = now.add(
        const Duration(seconds: AppConstants.checkInPromptTimeoutSeconds),
      );
      notifyListeners();
    }
  }

  Future<void> _handleMissedCheckIn() async {
    if (_handlingMissedCheckIn) {
      return;
    }

    _handlingMissedCheckIn = true;
    try {
      await _safetyRepository.createMissedCheckInAlert(
        profile: _currentUser,
        description: 'User did not respond to check-in.',
        showLocalWarning: (_settings ?? UserSettings.defaults(_userId))
            .checkInNotificationsEnabled,
      );
      _lastCheckInReferenceAt = DateTime.now();
      _clearCheckInPrompt();
      setInfo('A missed check-in alert was sent to guardians.');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Missed check-in alert failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error);
    } finally {
      _handlingMissedCheckIn = false;
    }
  }

  void _clearCheckInPrompt() {
    _checkInPromptStartedAt = null;
    _checkInPromptDeadline = null;
    notifyListeners();
  }

  Future<void> respondToCheckInPrompt() async {
    await guard<void>(
      () => _safetyRepository.sendManualCheckIn(
        profile: _currentUser,
        batteryLevel: _currentUser.batteryLevel,
      ),
      operationName: 'respond to check-in prompt',
    );

    if (errorMessage == null) {
      _lastCheckInReferenceAt = DateTime.now();
      _clearCheckInPrompt();
      setInfo('Check-in sent.');
    }
  }

  Future<void> startSafetyTimer(Duration duration) async {
    await guard<void>(
      () => _safetyRepository.startSafetyTimer(
        profile: _currentUser,
        duration: duration,
      ),
      operationName: 'start safety timer',
    );
    if (errorMessage == null) {
      setInfo('Safety timer set for ${duration.inMinutes} minutes.');
    }
  }

  Future<void> cancelSafetyTimer() async {
    await guard<void>(
      () => _safetyRepository.cancelSafetyTimer(userId: _currentUser.id),
      operationName: 'cancel safety timer',
    );
    if (errorMessage == null) {
      setInfo('Safety timer canceled.');
    }
  }

  Future<void> startRouteTracking({
    required double destinationLat,
    required double destinationLng,
  }) async {
    await guard<void>(
      () => _safetyRepository.startRouteTracking(
        profile: _currentUser,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
      ),
      operationName: 'start route tracking',
    );
    if (errorMessage == null) {
      setInfo('Journey monitoring started.');
    }
  }

  Future<void> stopRouteTracking() async {
    await guard<void>(
      () => _safetyRepository.stopRouteTracking(userId: _currentUser.id),
      operationName: 'stop route tracking',
    );
    if (errorMessage == null) {
      setInfo('Journey monitoring stopped.');
    }
  }

  void registerPanicTap() {
    final DateTime now = DateTime.now();
    final DateTime? lastTapAt = _lastPanicTapAt;
    if (lastTapAt == null || now.difference(lastTapAt).inSeconds > 2) {
      _panicTapCount = 1;
    } else {
      _panicTapCount++;
    }
    _lastPanicTapAt = now;

    if (_panicTapCount < 3) {
      return;
    }

    _panicTapCount = 0;
    _lastPanicTapAt = null;
    unawaited(triggerSilentPanic());
  }

  Future<void> triggerSilentPanic() async {
    if (_autoEmergencyInProgress || _currentUser.isEmergencyActive) {
      return;
    }

    _autoEmergencyInProgress = true;
    try {
      await _safetyRepository.triggerAutoEmergency(
        profile: _currentUser,
        settings: _settings ?? UserSettings.defaults(_userId),
        reason: 'panic_trigger',
        metadata: const <String, Object?>{'source': 'hidden_triple_tap'},
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Silent panic trigger failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error);
    } finally {
      _autoEmergencyInProgress = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _settingsSubscription?.cancel();
    _geofenceSubscription?.cancel();
    _checkInSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _runtimeSubscription?.cancel();
    _emergencyDetectionSubscription?.cancel();
    _monitorTimer?.cancel();
    _heartbeatTimer?.cancel();
    _emergencyConfirmationTimer?.cancel();
    unawaited(_emergencyDetectionService.stop());
    super.dispose();
  }
}

class EmergencyConfirmationState {
  const EmergencyConfirmationState({
    required this.event,
    required this.startedAt,
    required this.deadline,
  });

  final EmergencyEvent event;
  final DateTime startedAt;
  final DateTime deadline;

  Duration get remaining {
    final Duration duration = deadline.difference(DateTime.now());
    return duration.isNegative ? Duration.zero : duration;
  }
}
