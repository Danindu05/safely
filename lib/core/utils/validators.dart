class Validators {
  const Validators._();

  static String? name(String? value) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Enter your name.';
    }
    if (normalized.length < 2) {
      return 'Name must be at least 2 characters.';
    }
    return null;
  }

  static String? email(String? value) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Enter your email address.';
    }

    final RegExp emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(normalized)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  static String? password(String? value) {
    final String normalized = value ?? '';
    if (normalized.isEmpty) {
      return 'Enter your password.';
    }
    if (normalized.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) {
      return 'Confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? requiredField(String? value, String label) {
    if ((value?.trim() ?? '').isEmpty) {
      return 'Enter $label.';
    }
    return null;
  }

  static String? phone(String? value) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Enter a contact phone number.';
    }
    if (normalized.length < 7) {
      return 'Enter a valid phone number.';
    }
    return null;
  }
}
