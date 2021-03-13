class AuthException implements Exception {
  static const Map<String, String> errors = {
    'EMAIL_EXISTS': 'E-mail has already been registered!',
    'OPERATION_NOT_ALLOWED': 'Operation not allowed!',
    'TOO_MANY_ATTEMPTS_TRY_LATER': 'Try later!',
    'INVALID_PASSWORD': 'Invalid password!',
    'USER_DISABLED': 'Disabled user!',
    'EMAIL_NOT_FOUND': 'E-mail was not found!',
    'INVALID_EMAIL': 'Invalid e-mail!',
  };

  final String key;

  const AuthException(this.key);

  @override
  String toString() {
    if (errors.containsKey(key)) {
      return errors[key]!;
    } else {
      return 'Authentication error!';
    }
  }
}
