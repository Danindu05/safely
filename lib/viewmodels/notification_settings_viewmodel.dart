import 'dart:async';

import '../models/user_settings.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import 'base_viewmodel.dart';

class NotificationSettingsViewModel extends BaseViewModel {
  NotificationSettingsViewModel({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    required String guardianId,
  }) : _authRepository = authRepository,
       _profileRepository = profileRepository,
       _guardianId = guardianId {
    _settings = UserSettings.defaults(_guardianId);
    _subscription = _profileRepository.watchSettings(_guardianId).listen((
      UserSettings? settings,
    ) {
      _settings = settings ?? UserSettings.defaults(_guardianId);
      notifyListeners();
    });
  }

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final String _guardianId;
  StreamSubscription<UserSettings?>? _subscription;

  UserSettings? _settings;
  bool isSigningOut = false;

  UserSettings? get settings => _settings;

  Future<void> save(UserSettings settings) async {
    await guard<void>(
      () => _profileRepository.saveSettings(settings),
      operationName: 'save notification settings',
    );
    if (errorMessage == null) {
      setInfo('Notification settings saved.');
    }
  }

  Future<void> signOut() async {
    if (isSigningOut) {
      return;
    }

    isSigningOut = true;
    notifyListeners();

    try {
      await _authRepository.signOut();
    } finally {
      isSigningOut = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
