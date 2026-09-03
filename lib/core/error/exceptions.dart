/// Low-level errors thrown by the data layer (data sources).
///
/// These never leak past the repository – there they are mapped to
/// [Failure]s from `core/error/failure.dart`.
library;

class ServerException implements Exception {
  const ServerException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class ParseException implements Exception {
  const ParseException([this.message = 'Unexpected response format']);

  final String message;

  @override
  String toString() => 'ParseException: $message';
}
