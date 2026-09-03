import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

/// `PATCH /todos/{id}/complete` – mark a task completed (or uncompleted).
class SetTodoCompletion extends UseCase<Todo, SetTodoCompletionParams> {
  const SetTodoCompletion(this._repository);

  final TodoRepository _repository;

  @override
  ResultFuture<Todo> call(SetTodoCompletionParams params) {
    return _repository.setCompletion(
      id: params.id,
      completed: params.completed,
    );
  }
}

class SetTodoCompletionParams extends Equatable {
  const SetTodoCompletionParams({required this.id, required this.completed});

  final String id;
  final bool completed;

  @override
  List<Object?> get props => [id, completed];
}
