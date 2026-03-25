import 'dart:async';

import '../repositories/auth_repository.dart';
import '../models/user_settings.dart';
import '../repositories/profile_repository.dart';
import 'base_viewmodel.dart';

class SafetySettingsViewModel extends BaseViewModel {
  SafetySettingsViewModel({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    required String userId,
  }) : _authRepository = authRepository,
       _profileRepository = profileRepository,
       _userId = userId {
    _subscription = _profileRepository.watchSettings(_userId).listen((
      UserSettings? settings,
    ) {
      _settings = settings ?? UserSettings.defaults(_userId);
      notifyListeners();
    });
  }

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final String _userId;
  StreamSubscription<UserSettings?>? _subscription;
  UserSettings? _settings;

  UserSettings? get settings => _settings;

  Future<void> save(UserSettings settings) async {
    await guard<void>(() => _profileRepository.saveSettings(settings));
    setInfo('Safety settings saved.');
  }

  Future<void> signOut() async {
    await guard<void>(_authRepository.signOut);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
