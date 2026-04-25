// lib/utils/app_exceptions.dart

/// Exception dari response API (ada pesan dari server)
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final List<dynamic>? errors;

  const ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  bool get isUnauthorized   => statusCode == 401;
  bool get isForbidden      => statusCode == 403;
  bool get isNotFound       => statusCode == 404;
  bool get isValidationError => statusCode == 422;
  bool get isServerError    => statusCode >= 500;
}

/// Exception jaringan (timeout, no connection)
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Tidak ada koneksi internet']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception token expired / invalid
class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Sesi berakhir, silakan login ulang']);

  @override
  String toString() => 'AuthException: $message';
}
