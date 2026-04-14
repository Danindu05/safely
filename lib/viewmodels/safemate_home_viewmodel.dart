import 'dart:async';

import '../core/utils/app_logger.dart';
import '../models/safety_alert.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';
import '../repositories/alert_repository.dart';
import '../repositories/location_repository.dart';
import '../repositories/safety_repository.dart';
import 'base_viewmodel.dart';

class SafemateHomeViewModel extends BaseViewModel {
  SafemateHomeViewModel({
    required AlertRepository alertRepository,
    required LocationRepository locationRepository,
    required SafetyRepository safetyRepository,
    required UserProfile profile,
    required UserSettings? settings,
  }) : _alertRepository = alertRepository,
       _locationRepository = locationRepository,
       _safetyRepository = safetyRepository,
       _profile = profile,
       _settings = settings {
    _bind();
  }

  final AlertRepository _alertRepository;
  final LocationRepository _locationRepository;
  final SafetyRepository _safetyRepository;
  final UserProfile _profile;
  final UserSettings? _settings;

  StreamSubscription<List<SafetyAlert>>? _alertsSubscription;
  StreamSubscription<SafetyRuntimeState>? _runtimeSubscription;

  List<SafetyAlert> _alerts = const <SafetyAlert>[];
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

  List<SafetyAlert> get alerts => _alerts;
  SafetyAlert? get latestAlert => _alerts.isEmpty ? null : _alerts.first;
  SafetyRuntimeState get runtimeState => _runtimeState;

  void _bind() {
    _alertsSubscription = _alertRepository
        .watchAlertsForUser(_profile.id)
        .listen((List<SafetyAlert> alerts) {
          _alerts = alerts;
          notifyListeners();
        });
    _runtimeSubscription = _safetyRepository.runtimeState.listen((
      SafetyRuntimeState state,
    ) {
      _runtimeState = state;
      notifyListeners();
    });
  }

  Future<void> triggerSos() async {
    final UserSettings settings =
        _settings ?? UserSettings.defaults(_profile.id);

    await guard<void>(
      () => _safetyRepository.triggerSos(profile: _profile, settings: settings),
      operationName: 'trigger SOS',
    );
  }

  Future<void> sendCheckIn(int? batteryLevel) async {
    await guard<void>(
      () => _safetyRepository.sendManualCheckIn(
        profile: _profile,
        batteryLevel: batteryLevel,
      ),
      operationName: 'send manual check-in',
    );
    if (errorMessage == null) {
      setInfo('Manual check-in sent.');
    }
  }

  Future<void> toggleManualLiveSharing() async {
    await guard<void>(() {
      if (_runtimeState.isLiveSharingActive) {
        return _safetyRepository.stopManualLiveSharing(_profile.id);
      }
      return _safetyRepository.startManualLiveSharing(profile: _profile);
    }, operationName: 'toggle manual live sharing');
  }

  Future<(double lat, double lng)> loadRoutePickerInitialPosition() async {
    try {
      final current = await _locationRepository.getCurrentPosition();
      return (current.latitude, current.longitude);
    } catch (error) {
      AppLogger.warning(
        'Could not load current position for route picker. Falling back. error=$error',
      );
    }

    try {
      final lastKnown = await _locationRepository.getLastKnownPosition();
      if (lastKnown != null) {
        return (lastKnown.latitude, lastKnown.longitude);
      }
    } catch (error) {
      AppLogger.warning(
        'Could not load last known position for route picker. error=$error',
      );
    }

    return (6.9271, 79.8612);
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    _runtimeSubscription?.cancel();
    super.dispose();
  }
}
