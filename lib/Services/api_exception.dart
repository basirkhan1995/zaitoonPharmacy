class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;   // e.g. 'TOKEN_EXPIRED', 'TOKEN_INVALID'

  ApiException(
      this.message, {
        this.statusCode,
        this.code,
      });

  bool get isTokenExpired => code == 'TOKEN_EXPIRED';
  bool get isTokenInvalid => code == 'TOKEN_INVALID';
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}