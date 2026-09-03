import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

/// Lightweight request/response logger, active only in debug builds.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '→ ${options.method} ${options.uri}'
        '${options.queryParameters.isEmpty ? '' : ' query=${options.queryParameters}'}'
        '${options.data == null ? '' : ' body=${options.data}'}',
        name: 'API',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '← ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri}',
        name: 'API',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '✖ ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.method} ${err.requestOptions.uri} – ${err.message}',
        name: 'API',
        error: err,
      );
    }
    handler.next(err);
  }
}
