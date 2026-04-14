import '../core/utils/app_logger.dart';
import '../models/auth_account.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import 'base_viewmodel.dart';

class SignupViewModel extends BaseViewModel {
  SignupViewModel(this._authRepository, this._profileRepository);

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final AuthAccount? result = await guard<AuthAccount>(() async {
      final AuthAccount account = await _authRepository.signUp(
        name: name.trim(),
        email: email.trim(),
        password: password,
      );

      try {
        await _profileRepository.ensureAccountScaffold(
          uid: account.id,
          name: name.trim(),
          email: email.trim(),
        );
      } catch (error, stackTrace) {
        AppLogger.error(
          'Signup bootstrap will retry from the authenticated session.',
          error: error,
          stackTrace: stackTrace,
        );
      }

      return account;
    }, operationName: 'create account');
    return result != null;
  }
}
