import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/paginated_todos.dart';
import '../entities/todo.dart';

/// Domain-facing contract for the Todos API. The implementation lives in the
/// data layer; the presentation layer only ever sees this interface.
abstract class TodoRepository {
  /// `GET /todos` – paginated, optionally filtered by status / importance.
  ResultFuture<PaginatedTodos> getTodos({
    int page = ApiConstants.defaultPage,
    int limit = ApiConstants.defaultPageSize,
    bool? completed,
    bool? important,
  });

  /// `POST /todos` – create a task.
  ResultFuture<Todo> addTodo({
    required String title,
    bool important = false,
  });

  /// `PATCH /todos/{id}` – edit title and/or toggle important / completed.
  ResultFuture<Todo> updateTodo({
    required String id,
    String? title,
    bool? important,
    bool? completed,
  });

  /// `DELETE /todos/{id}` – remove a task.
  ResultVoid deleteTodo(String id);

  /// `PATCH /todos/{id}/complete` – mark completed / uncompleted.
  ResultFuture<Todo> setCompletion({
    required String id,
    required bool completed,
  });
}
