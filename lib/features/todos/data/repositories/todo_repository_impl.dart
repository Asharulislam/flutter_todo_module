import 'package:dartz/dartz.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/paginated_todos.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/todo_remote_data_source.dart';

/// Bridges the domain [TodoRepository] contract to the remote data source,
/// converting data-layer [Exception]s into domain [Failure]s.
class TodoRepositoryImpl implements TodoRepository {
  const TodoRepositoryImpl(this._remote);

  final TodoRemoteDataSource _remote;

  @override
  ResultFuture<PaginatedTodos> getTodos({
    int page = ApiConstants.defaultPage,
    int limit = ApiConstants.defaultPageSize,
    bool? completed,
    bool? important,
  }) {
    return _execute(
      () => _remote.getTodos(
        page: page,
        limit: limit,
        completed: completed,
        important: important,
      ),
    );
  }

  @override
  ResultFuture<Todo> addTodo({required String title, bool important = false}) {
    return _execute(() => _remote.addTodo(title: title, important: important));
  }

  @override
  ResultFuture<Todo> updateTodo({
    required String id,
    String? title,
    bool? important,
    bool? completed,
  }) {
    return _execute(
      () => _remote.updateTodo(
        id: id,
        title: title,
        important: important,
        completed: completed,
      ),
    );
  }

  @override
  ResultVoid deleteTodo(String id) {
    return _execute(() => _remote.deleteTodo(id));
  }

  @override
  ResultFuture<Todo> setCompletion({
    required String id,
    required bool completed,
  }) {
    return _execute(() => _remote.setCompletion(id: id, completed: completed));
  }

  /// Runs [action], mapping known exceptions to [Failure]s.
  Future<Either<Failure, T>> _execute<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParseException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
