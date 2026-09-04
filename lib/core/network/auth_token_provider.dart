import 'package:flutter/foundation.dart';
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

/// TEMPORARY debug provider that returns a fixed token, bypassing the native
/// bridge entirely. Use to isolate whether failures come from the platform
/// channel or from the backend itself. Swap back to
/// [MethodChannelAuthTokenProvider] in `injection_container.dart` once done.
class HardcodedAuthTokenProvider implements AuthTokenProvider {
  const HardcodedAuthTokenProvider();

  static const String _token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwiaWF0IjoxNzg4NTM3OTg3LCJleHAiOjE3ODkxNDI3ODd9.TApoM-KOTFc8C_eralMJ-VqhMV-jeGSlkXES7PvFy6A';

  @override
  Future<String?> getToken() async => _token;
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
      final token = await _channel.invokeMethod<String>('getToken');
      debugPrint('[AuthBridge] getToken() -> ${token == null ? 'null' : '${token.length} chars'}');
      return token;
    } on PlatformException catch (e) {
      debugPrint('[AuthBridge] PlatformException: ${e.code} ${e.message}');
      return null;
    } on MissingPluginException catch (e) {
      debugPrint('[AuthBridge] MissingPluginException: $e');
      return null;
    }
  }
}
