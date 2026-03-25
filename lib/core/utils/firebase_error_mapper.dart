import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class FirebaseErrorMapper {
  const FirebaseErrorMapper._();

  static String map(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'That email address is already registered.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'The email or password is incorrect.';
        case 'weak-password':
          return 'Use a password with at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Check the connection and try again.';
      }

      return error.message ?? 'Authentication failed. Please try again.';
    }

    if (error is PlatformException) {
      return error.message ?? 'Device permission or service error.';
    }

    if (error is FormatException) {
      return error.message;
    }

    if (error is StateError) {
      return error.message.toString();
    }

    return 'Something went wrong. Please try again.';
  }
}
