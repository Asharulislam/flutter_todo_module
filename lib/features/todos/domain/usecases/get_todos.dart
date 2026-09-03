import 'package:equatable/equatable.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/paginated_todos.dart';
import '../repositories/todo_repository.dart';

/// `GET /todos` – list tasks with pagination and filtering.
class GetTodos extends UseCase<PaginatedTodos, GetTodosParams> {
  const GetTodos(this._repository);

  final TodoRepository _repository;

  @override
  ResultFuture<PaginatedTodos> call(GetTodosParams params) {
    return _repository.getTodos(
      page: params.page,
      limit: params.limit,
      completed: params.completed,
      important: params.important,
    );
  }
}

class GetTodosParams extends Equatable {
  const GetTodosParams({
    this.page = ApiConstants.defaultPage,
    this.limit = ApiConstants.defaultPageSize,
    this.completed,
    this.important,
  });

  final int page;
  final int limit;
  final bool? completed;
  final bool? important;

  @override
  List<Object?> get props => [page, limit, completed, important];
}
