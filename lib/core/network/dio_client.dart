import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import 'api_interceptors.dart';
import 'auth_token_provider.dart';

/// Thin wrapper that owns a fully configured [Dio] instance.
///
/// Data sources depend on this rather than on `Dio` directly, so base URL,
/// timeouts and interceptors are configured in exactly one place.
class DioClient {
  DioClient({
    required AuthTokenProvider tokenProvider,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = ApiConstants.baseUrl
      ..connectTimeout = ApiConstants.connectTimeout
      ..receiveTimeout = ApiConstants.receiveTimeout
      ..sendTimeout = ApiConstants.sendTimeout
      ..headers = <String, dynamic>{
        Headers.contentTypeHeader: Headers.jsonContentType,
        Headers.acceptHeader: Headers.jsonContentType,
      }
      ..responseType = ResponseType.json;

    _dio.interceptors.add(AuthInterceptor(tokenProvider));
    if (kDebugMode) {
      _dio.interceptors.add(LoggingInterceptor());
    }
  }

  final Dio _dio;

  Dio get dio => _dio;
}
