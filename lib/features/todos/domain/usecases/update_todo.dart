import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

/// `PATCH /todos/{id}` – edit title, toggle important, toggle completed.
class UpdateTodo extends UseCase<Todo, UpdateTodoParams> {
  const UpdateTodo(this._repository);

  final TodoRepository _repository;

  @override
  ResultFuture<Todo> call(UpdateTodoParams params) {
    return _repository.updateTodo(
      id: params.id,
      title: params.title,
      important: params.important,
      completed: params.completed,
    );
  }
}

class UpdateTodoParams extends Equatable {
  const UpdateTodoParams({
    required this.id,
    this.title,
    this.important,
    this.completed,
  });

  final String id;
  final String? title;
  final bool? important;
  final bool? completed;

  @override
  List<Object?> get props => [id, title, important, completed];
}
