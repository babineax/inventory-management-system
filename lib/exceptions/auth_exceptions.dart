class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, [this.code]);

  @override
  String toString() {
    if (code != null) {
      return 'AuthException: $message (Code: $code)';
    }
    return 'AuthException: $message';
  }
}

class UserNotFoundException extends AuthException {
  UserNotFoundException(String email)
      : super('User with email $email not found', 'user_not_found');
}

class InvalidPasswordException extends AuthException {
  InvalidPasswordException()
      : super('Invalid password provided', 'invalid_password');
}

class InvalidEmailException extends AuthException {
  InvalidEmailException(String email)
      : super('Invalid email address: $email', 'invalid_email');
}

class UserDisabledException extends AuthException {
  UserDisabledException()
      : super('User account has been disabled', 'user_disabled');
}

class EmailAlreadyInUseException extends AuthException {
  EmailAlreadyInUseException(String email)
      : super('Email address $email is already in use', 'email_already_in_use');
}

class OperationNotAllowedException extends AuthException {
  OperationNotAllowedException()
      : super(
            'Email/password accounts are not enabled', 'operation_not_allowed');
}

class WeakPasswordException extends AuthException {
  WeakPasswordException() : super('Password is too weak', 'weak_password');
}

class NetworkRequestFailedException extends AuthException {
  NetworkRequestFailedException()
      : super('Network error. Please check your connection',
            'network_request_failed');
}

class UserNotAuthenticatedException extends AuthException {
  UserNotAuthenticatedException()
      : super('No user is currently signed in', 'user_not_authenticated');
}

class UserProfileUpdateException extends AuthException {
  UserProfileUpdateException(String reason)
      : super('Failed to update user profile: $reason',
            'user_profile_update_failed');
}

class UserPromotionException extends AuthException {
  UserPromotionException(String reason)
      : super('Failed to promote user: $reason', 'user_promotion_failed');
}

class UserLoadingException extends AuthException {
  UserLoadingException(String reason)
      : super('Failed to load users: $reason', 'user_loading_failed');
}
