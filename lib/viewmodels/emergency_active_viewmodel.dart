import 'dart:async';

import '../models/safety_alert.dart';
import '../models/user_profile.dart';
import '../repositories/alert_repository.dart';
import '../repositories/safety_repository.dart';
import 'base_viewmodel.dart';

class EmergencyActiveViewModel extends BaseViewModel {
  EmergencyActiveViewModel({
    required AlertRepository alertRepository,
    required SafetyRepository safetyRepository,
    required UserProfile profile,
  }) : _alertRepository = alertRepository,
       _safetyRepository = safetyRepository,
       _profile = profile {
    _runtimeSubscription = _safetyRepository.runtimeState.listen((
      SafetyRuntimeState state,
    ) {
      _runtimeState = state;
      _watchAlert();
      notifyListeners();
    });
    _watchAlert();
  }

  final AlertRepository _alertRepository;
  final SafetyRepository _safetyRepository;
  final UserProfile _profile;

  StreamSubscription<SafetyRuntimeState>? _runtimeSubscription;
  StreamSubscription<SafetyAlert?>? _alertSubscription;

  SafetyRuntimeState _runtimeState = const SafetyRuntimeState(
    isLiveSharingActive: false,
    isRecordingActive: false,
    isAudioUploading: false,
    audioUploadError: null,
    activeAlertId: null,
    isTrustedPlaceActive: false,
    isNightMonitoringActive: false,
    activeRouteTracking: null,
    safetyTimer: null,
  );
  SafetyAlert? _alert;

  SafetyRuntimeState get runtimeState => _runtimeState;
  SafetyAlert? get alert => _alert;

  void _watchAlert() {
    final String? alertId = _runtimeState.activeAlertId;
    if (alertId == null) {
      return;
    }

    _alertSubscription?.cancel();
    _alertSubscription = _alertRepository.watchAlert(alertId).listen((
      SafetyAlert? alert,
    ) {
      _alert = alert;
      notifyListeners();
    });
  }

  Future<void> cancelFalseAlarm() async {
    await guard<void>(
      () =>
          _safetyRepository.stopEmergency(profile: _profile, falseAlarm: true),
    );
  }

  Future<void> resolveEmergency() async {
    await guard<void>(
      () =>
          _safetyRepository.stopEmergency(profile: _profile, falseAlarm: false),
    );
  }

  @override
  void dispose() {
    _runtimeSubscription?.cancel();
    _alertSubscription?.cancel();
    super.dispose();
  }
}
