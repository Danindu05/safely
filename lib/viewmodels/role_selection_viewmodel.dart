import '../models/app_enums.dart';
import '../models/user_settings.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import 'base_viewmodel.dart';

class RoleSelectionViewModel extends BaseViewModel {
  RoleSelectionViewModel({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    required String userId,
    required String email,
  }) : _authRepository = authRepository,
       _profileRepository = profileRepository,
       _userId = userId,
       _email = email;

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final String _userId;
  final String _email;

  UserRole? _selectedRole;

  UserRole? get selectedRole => _selectedRole;

  void selectRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  Future<bool> saveRole({required String name}) async {
    if (_selectedRole == null) {
      setError(StateError('Choose whether you are a Safemate or Guardian.'));
      return false;
    }

    final bool? result = await guard<bool>(() async {
      await _authRepository.updateDisplayName(name.trim());
      await _profileRepository.setRole(
        uid: _userId,
        name: name.trim(),
        email: _email,
        roleValue: _selectedRole!.value,
      );
      await _profileRepository.saveSettings(UserSettings.defaults(_userId));
      return true;
    });
    return result ?? false;
  }
}
