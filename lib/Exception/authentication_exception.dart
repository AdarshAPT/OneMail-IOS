// ignore_for_file: constant_identifier_names

enum ExceptionType {
  AuthFailed,
  APIFailed,
  InvalidCred,
  TokenException,
  UserAlreadyExist,
  UserNotFound,
  Unknown,
}

class AuthException implements Exception {
  final ExceptionType type;
  final String message;

  AuthException(this.type, this.message);
}
