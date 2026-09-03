import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/todo_repository.dart';

/// `DELETE /todos/{id}` – delete a task.
class DeleteTodo extends UseCase<void, DeleteTodoParams> {
  const DeleteTodo(this._repository);

  final TodoRepository _repository;

  @override
  ResultVoid call(DeleteTodoParams params) => _repository.deleteTodo(params.id);
}

class DeleteTodoParams extends Equatable {
  const DeleteTodoParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
