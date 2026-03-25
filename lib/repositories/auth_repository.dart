import '../core/services/firebase_auth_service.dart';
import '../models/auth_account.dart';

abstract class AuthRepository {
  Stream<AuthAccount?> authStateChanges();

  AuthAccount? get currentUser;

  Future<AuthAccount> signIn({required String email, required String password});

  Future<AuthAccount> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> updateDisplayName(String name);

  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._authService);

  final FirebaseAuthService _authService;

  @override
  Stream<AuthAccount?> authStateChanges() {
    return _authService.authStateChanges();
  }

  @override
  AuthAccount? get currentUser => _authService.currentUser;

  @override
  Future<AuthAccount> signIn({
    required String email,
    required String password,
  }) {
    return _authService.signIn(email: email, password: password);
  }

  @override
  Future<AuthAccount> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _authService.signUp(name: name, email: email, password: password);
  }

  @override
  Future<void> updateDisplayName(String name) {
    return _authService.updateDisplayName(name);
  }

  @override
  Future<void> signOut() {
    return _authService.signOut();
  }
}
