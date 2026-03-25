import 'dart:async';

import '../core/services/connectivity_service.dart';
import '../models/geofence_zone.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';
import '../repositories/profile_repository.dart';
import '../repositories/safety_repository.dart';
import 'base_viewmodel.dart';

class SafemateShellViewModel extends BaseViewModel {
  SafemateShellViewModel({
    required ProfileRepository profileRepository,
    required SafetyRepository safetyRepository,
    required ConnectivityService connectivityService,
    required UserProfile initialUser,
  }) : _profileRepository = profileRepository,
       _safetyRepository = safetyRepository,
       _connectivityService = connectivityService,
       _userId = initialUser.id,
       _currentUser = initialUser {
    _bind();
  }

  final ProfileRepository _profileRepository;
  final SafetyRepository _safetyRepository;
  final ConnectivityService _connectivityService;
  final String _userId;

  StreamSubscription<UserProfile?>? _userSubscription;
  StreamSubscription<UserSettings?>? _settingsSubscription;
  StreamSubscription<GeofenceConfig?>? _geofenceSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<SafetyRuntimeState>? _runtimeSubscription;
  Timer? _monitorTimer;

  UserProfile _currentUser;
  UserSettings? _settings;
  GeofenceConfig? _geofenceConfig;
  bool _isOnline = true;
  SafetyRuntimeState _runtimeState = const SafetyRuntimeState(
    isLiveSharingActive: false,
    isRecordingActive: false,
    activeAlertId: null,
    isTrustedPlaceActive: false,
    isNightMonitoringActive: false,
  );

  UserProfile get currentUser => _currentUser;
  UserSettings? get settings => _settings;
  GeofenceConfig? get geofenceConfig => _geofenceConfig;
  bool get isOnline => _isOnline;
  SafetyRuntimeState get runtimeState => _runtimeState;

  void _bind() {
    _userSubscription = _profileRepository.watchUserProfile(_userId).listen((
      UserProfile? user,
    ) {
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    });
    _settingsSubscription = _profileRepository.watchSettings(_userId).listen((
      UserSettings? settings,
    ) {
      _settings = settings;
      notifyListeners();
    });
    _geofenceSubscription = _profileRepository.watchGeofences(_userId).listen((
      GeofenceConfig? config,
    ) {
      _geofenceConfig = config;
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
      notifyListeners();
    });

    _monitorTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _runMonitors(),
    );
    _runMonitors();
  }

  Future<void> _runMonitors() async {
    if (_settings == null) {
      return;
    }

    await _profileRepository.updateLastSeen(_userId);
    final GeofenceConfig geofenceConfig =
        _geofenceConfig ?? GeofenceConfig.empty(_userId);
    await _safetyRepository.evaluateMonitoringModes(
      profile: _currentUser,
      geofenceConfig: geofenceConfig,
      settings: _settings!,
    );
    await _safetyRepository.maybeCreateBatteryAlert(
      profile: _currentUser,
      settings: _settings!,
    );

    if (_geofenceConfig != null) {
      await _safetyRepository.evaluateGeofences(
        profile: _currentUser,
        geofenceConfig: _geofenceConfig!,
        settings: _settings!,
      );
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _settingsSubscription?.cancel();
    _geofenceSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _runtimeSubscription?.cancel();
    _monitorTimer?.cancel();
    super.dispose();
  }
}
