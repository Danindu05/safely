import '../repositories/auth_repository.dart';
import 'base_viewmodel.dart';

class LoginViewModel extends BaseViewModel {
  LoginViewModel(this._authRepository);

  final AuthRepository _authRepository;

  Future<bool> signIn({required String email, required String password}) async {
    final Object? result = await guard<Object?>(
      () => _authRepository.signIn(email: email.trim(), password: password),
    );
    return result != null;
  }
}
