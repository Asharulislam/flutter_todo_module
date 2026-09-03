/// Central place for every network-related constant.
///
/// Only [baseUrl] normally needs to change between environments – point it at
/// your real host (or wire it to a build-time `--dart-define`).
class ApiConstants {
  const ApiConstants._();

  /// TODO: replace with the real API host.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  // ---------------------------------------------------------------------------
  // Timeouts
  // ---------------------------------------------------------------------------
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  // ---------------------------------------------------------------------------
  // Endpoints
  // ---------------------------------------------------------------------------
  static const String todos = '/todos';

  static String todoById(String id) => '/todos/$id';

  static String completeTodo(String id) => '/todos/$id/complete';

  // ---------------------------------------------------------------------------
  // Query / body keys
  // ---------------------------------------------------------------------------
  static const String paramPage = 'page';
  static const String paramLimit = 'limit';
  static const String paramCompleted = 'completed';
  static const String paramImportant = 'important';
  static const String keyTitle = 'title';

  // ---------------------------------------------------------------------------
  // Headers
  // ---------------------------------------------------------------------------
  static const String headerAuthorization = 'Authorization';
  static const String bearerPrefix = 'Bearer ';

  // ---------------------------------------------------------------------------
  // Paging defaults
  // ---------------------------------------------------------------------------
  static const int defaultPage = 1;
  static const int defaultPageSize = 20;
}
