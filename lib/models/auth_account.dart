class AuthAccount {
  const AuthAccount({required this.id, required this.email, this.displayName});

  final String id;
  final String email;
  final String? displayName;

  String get fallbackName {
    final String trimmedName = displayName?.trim() ?? '';
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }

    return email.split('@').first;
  }
}
