/// Supplies the bearer token attached to every outgoing API request.
///
/// Authentication is owned by the Android native side of this module, so the
/// Flutter layer only *reads* a token it never creates. When the native bridge
/// is ready, provide an implementation that returns that token and register it
/// in `di/injection_container.dart` – nothing else in the app needs to change.
abstract class AuthTokenProvider {
  Future<String?> getToken();
}

/// Default no-op used until the native token bridge is wired up. The app runs
/// unauthenticated with this in place.
class NoAuthTokenProvider implements AuthTokenProvider {
  const NoAuthTokenProvider();

  @override
  Future<String?> getToken() async => null;
}
