import 'package:flutter/services.dart';

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

/// Reads the token from the Android host app via the `getToken` method on
/// the `com.todo.myapplication/auth` MethodChannel set up in `MyApplication`.
class MethodChannelAuthTokenProvider implements AuthTokenProvider {
  MethodChannelAuthTokenProvider({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.todo.myapplication/auth');

  final MethodChannel _channel;

  @override
  Future<String?> getToken() async {
    try {
      return await _channel.invokeMethod<String>('getToken');
    } on PlatformException {
      return null;
    }
  }
}
