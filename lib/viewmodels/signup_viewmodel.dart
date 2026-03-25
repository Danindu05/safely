import '../repositories/auth_repository.dart';
import 'base_viewmodel.dart';

class SignupViewModel extends BaseViewModel {
  SignupViewModel(this._authRepository);

  final AuthRepository _authRepository;

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final Object? result = await guard<Object?>(
      () => _authRepository.signUp(
        name: name.trim(),
        email: email.trim(),
        password: password,
      ),
    );
    return result != null;
  }
}
