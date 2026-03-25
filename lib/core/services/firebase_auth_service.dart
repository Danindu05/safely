import 'package:firebase_auth/firebase_auth.dart';

import '../../models/auth_account.dart';

class FirebaseAuthService {
  FirebaseAuthService(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  Stream<AuthAccount?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  AuthAccount? get currentUser => _mapUser(_firebaseAuth.currentUser);

  Future<AuthAccount> signIn({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _firebaseAuth
        .signInWithEmailAndPassword(email: email, password: password);

    final AuthAccount? user = _mapUser(credential.user);
    if (user == null) {
      throw StateError('Sign in completed without a valid user session.');
    }
    return user;
  }

  Future<AuthAccount> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);

    final User? user = credential.user;
    if (user == null) {
      throw StateError('Account creation completed without a valid user.');
    }

    if (name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
      await user.reload();
    }

    final AuthAccount? account = _mapUser(_firebaseAuth.currentUser);
    if (account == null) {
      throw StateError('Account created but no authenticated session found.');
    }

    return account;
  }

  Future<void> updateDisplayName(String name) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user was found.');
    }

    await user.updateDisplayName(name.trim());
    await user.reload();
  }

  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  AuthAccount? _mapUser(User? user) {
    if (user == null || user.email == null) {
      return null;
    }

    return AuthAccount(
      id: user.uid,
      email: user.email!,
      displayName: user.displayName,
    );
  }
}
