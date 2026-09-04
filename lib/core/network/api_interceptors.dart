import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'auth_token_provider.dart';

/// Attaches `Authorization: Bearer <token>` when a token is available.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenProvider);

  final AuthTokenProvider _tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenProvider.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers[ApiConstants.headerAuthorization] =
          '${ApiConstants.bearerPrefix}$token';
    }
    handler.next(options);
  }
}
