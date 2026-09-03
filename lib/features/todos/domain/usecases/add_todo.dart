import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

/// `POST /todos` – add a task.
class AddTodo extends UseCase<Todo, AddTodoParams> {
  const AddTodo(this._repository);

  final TodoRepository _repository;

  @override
  ResultFuture<Todo> call(AddTodoParams params) {
    return _repository.addTodo(
      title: params.title,
      important: params.important,
    );
  }
}

class AddTodoParams extends Equatable {
  const AddTodoParams({required this.title, this.important = false});

  final String title;
  final bool important;

  @override
  List<Object?> get props => [title, important];
}
