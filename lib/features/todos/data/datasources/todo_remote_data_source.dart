import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/typedefs.dart';
import '../models/paginated_todos_model.dart';
import '../models/todo_model.dart';

/// Talks to the raw `/todos` HTTP endpoints and returns data-layer models.
/// Every Dio error is translated into a typed [ServerException] /
/// [NetworkException] here so the repository above stays transport-agnostic.
abstract class TodoRemoteDataSource {
  Future<PaginatedTodosModel> getTodos({
    required int page,
    required int limit,
    bool? completed,
    bool? important,
  });

  Future<TodoModel> addTodo({required String title, bool important = false});

  Future<TodoModel> updateTodo({
    required String id,
    String? title,
    bool? important,
    bool? completed,
  });

  Future<void> deleteTodo(String id);

  Future<TodoModel> setCompletion({required String id, required bool completed});
}

class TodoRemoteDataSourceImpl implements TodoRemoteDataSource {
  const TodoRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<PaginatedTodosModel> getTodos({
    required int page,
    required int limit,
    bool? completed,
    bool? important,
  }) {
    return _guard(() async {
      final response = await _client.dio.get<dynamic>(
        ApiConstants.todos,
        queryParameters: <String, dynamic>{
          ApiConstants.paramPage: page,
          ApiConstants.paramLimit: limit,
          ApiConstants.paramCompleted: ?completed,
          ApiConstants.paramImportant: ?important,
        },
      );
      return PaginatedTodosModel.fromResponse(
        response.data,
        requestedPage: page,
        requestedLimit: limit,
      );
    });
  }

  @override
  Future<TodoModel> addTodo({required String title, bool important = false}) {
    return _guard(() async {
      final response = await _client.dio.post<dynamic>(
        ApiConstants.todos,
        data: <String, dynamic>{
          ApiConstants.keyTitle: title,
          ApiConstants.paramImportant: important,
        },
      );
      return TodoModel.fromJson(_unwrap(response.data));
    });
  }

  @override
  Future<TodoModel> updateTodo({
    required String id,
    String? title,
    bool? important,
    bool? completed,
  }) {
    return _guard(() async {
      final response = await _client.dio.patch<dynamic>(
        ApiConstants.todoById(id),
        data: <String, dynamic>{
          ApiConstants.keyTitle: ?title,
          ApiConstants.paramImportant: ?important,
          ApiConstants.paramCompleted: ?completed,
        },
      );
      return TodoModel.fromJson(_unwrap(response.data));
    });
  }

  @override
  Future<void> deleteTodo(String id) {
    return _guard(() => _client.dio.delete<dynamic>(ApiConstants.todoById(id)));
  }

  @override
  Future<TodoModel> setCompletion({
    required String id,
    required bool completed,
  }) {
    return _guard(() async {
      final response = await _client.dio.patch<dynamic>(
        ApiConstants.completeTodo(id),
        data: <String, dynamic>{ApiConstants.paramCompleted: completed},
      );
      return TodoModel.fromJson(_unwrap(response.data));
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Pulls the todo object out of either a bare body or a `{ "data": {...} }`
  /// envelope.
  DataMap _unwrap(dynamic body) {
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final inner = map['data'] ?? map['todo'] ?? map['result'];
      if (inner is Map) return Map<String, dynamic>.from(inner);
      return map;
    }
    throw const ParseException();
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Exception _mapDioException(DioException error) {
    final isConnectivityIssue = error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
    if (isConnectivityIssue) {
      return const NetworkException();
    }

    if (error.type == DioExceptionType.badResponse) {
      return ServerException(
        _messageFromBody(error.response?.data) ??
            'Request failed with status ${error.response?.statusCode}',
        statusCode: error.response?.statusCode,
      );
    }

    return ServerException(
      error.message ?? 'Request failed',
      statusCode: error.response?.statusCode,
    );
  }

  String? _messageFromBody(dynamic body) {
    if (body is Map) {
      final message = body['message'] ?? body['error'] ?? body['detail'];
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) return message.first.toString();
    }
    return null;
  }
}
