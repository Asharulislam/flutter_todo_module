import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/todo.dart';
import '../../domain/usecases/add_todo.dart';
import '../../domain/usecases/delete_todo.dart';
import '../../domain/usecases/get_todos.dart';
import '../../domain/usecases/set_todo_completion.dart';
import '../../domain/usecases/update_todo.dart';
import 'todo_filter.dart';

part 'todo_state.dart';

/// Orchestrates every Todos screen interaction by delegating to use cases and
/// reducing their results into a [TodoState].
class TodoCubit extends Cubit<TodoState> {
  TodoCubit({
    required GetTodos getTodos,
    required AddTodo addTodo,
    required UpdateTodo updateTodo,
    required DeleteTodo deleteTodo,
    required SetTodoCompletion setTodoCompletion,
  })  : _getTodos = getTodos,
        _addTodo = addTodo,
        _updateTodo = updateTodo,
        _deleteTodo = deleteTodo,
        _setTodoCompletion = setTodoCompletion,
        super(const TodoState());

  final GetTodos _getTodos;
  final AddTodo _addTodo;
  final UpdateTodo _updateTodo;
  final DeleteTodo _deleteTodo;
  final SetTodoCompletion _setTodoCompletion;

  /// First page load / full reload. Also used for pull-to-refresh.
  Future<void> loadTodos({TodoFilter? filter}) async {
    final activeFilter = filter ?? state.filter;
    emit(
      state.copyWith(
        status: TodoStatus.loading,
        filter: activeFilter,
        clearErrorMessage: true,
      ),
    );

    final result = await _getTodos(
      GetTodosParams(
        page: ApiConstants.defaultPage,
        completed: activeFilter.completedQuery,
        important: activeFilter.importantQuery,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TodoStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (data) => emit(
        state.copyWith(
          status: TodoStatus.success,
          todos: data.items,
          page: data.page,
          totalPages: data.totalPages,
        ),
      ),
    );
  }

  Future<void> refresh() => loadTodos();

  Future<void> changeFilter(TodoFilter filter) async {
    if (filter == state.filter) return;
    await loadTodos(filter: filter);
  }

  /// Appends the next page when the user scrolls near the bottom.
  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.status != TodoStatus.success) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    final result = await _getTodos(
      GetTodosParams(
        page: state.page + 1,
        completed: state.filter.completedQuery,
        important: state.filter.importantQuery,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoadingMore: false,
          actionError: failure.message,
        ),
      ),
      (data) => emit(
        state.copyWith(
          isLoadingMore: false,
          todos: [...state.todos, ...data.items],
          page: data.page,
          totalPages: data.totalPages,
        ),
      ),
    );
  }

  Future<void> addTodo(String title, {bool important = false}) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || state.isMutating) return;

    emit(state.copyWith(isMutating: true, clearActionError: true));

    final result = await _addTodo(
      AddTodoParams(title: trimmed, important: important),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isMutating: false, actionError: failure.message),
      ),
      (todo) => emit(
        state.copyWith(
          isMutating: false,
          todos: _reconcile(state.todos, todo, insertAtTop: true),
        ),
      ),
    );
  }

  Future<void> editTitle(String id, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    await _mutate(UpdateTodoParams(id: id, title: trimmed), _updateTodo);
  }

  Future<void> toggleImportant(Todo todo) async {
    await _mutate(
      UpdateTodoParams(id: todo.id, important: !todo.important),
      _updateTodo,
    );
  }

  Future<void> toggleCompleted(Todo todo) async {
    if (state.isMutating) return;
    emit(state.copyWith(isMutating: true, clearActionError: true));

    final result = await _setTodoCompletion(
      SetTodoCompletionParams(id: todo.id, completed: !todo.completed),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isMutating: false, actionError: failure.message),
      ),
      (updated) => emit(
        state.copyWith(
          isMutating: false,
          todos: _reconcile(state.todos, updated),
        ),
      ),
    );
  }

  Future<void> deleteTodo(String id) async {
    if (state.isMutating) return;
    emit(state.copyWith(isMutating: true, clearActionError: true));

    final result = await _deleteTodo(DeleteTodoParams(id));

    result.fold(
      (failure) => emit(
        state.copyWith(isMutating: false, actionError: failure.message),
      ),
      (_) => emit(
        state.copyWith(
          isMutating: false,
          todos: state.todos.where((t) => t.id != id).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _mutate(
    UpdateTodoParams params,
    UpdateTodo useCase,
  ) async {
    if (state.isMutating) return;
    emit(state.copyWith(isMutating: true, clearActionError: true));

    final result = await useCase(params);

    result.fold(
      (failure) => emit(
        state.copyWith(isMutating: false, actionError: failure.message),
      ),
      (updated) => emit(
        state.copyWith(
          isMutating: false,
          todos: _reconcile(state.todos, updated),
        ),
      ),
    );
  }

  /// Inserts / updates / drops [todo] in [list] so the list stays consistent
  /// with the active filter after a mutation.
  List<Todo> _reconcile(
    List<Todo> list,
    Todo todo, {
    bool insertAtTop = false,
  }) {
    final withoutTodo = list.where((t) => t.id != todo.id).toList();
    if (!_matchesFilter(todo)) return withoutTodo;
    return insertAtTop ? [todo, ...withoutTodo] : _replaceOrAppend(list, todo);
  }

  List<Todo> _replaceOrAppend(List<Todo> list, Todo todo) {
    final index = list.indexWhere((t) => t.id == todo.id);
    if (index == -1) return [todo, ...list];
    final copy = [...list];
    copy[index] = todo;
    return copy;
  }

  bool _matchesFilter(Todo todo) => switch (state.filter) {
        TodoFilter.all => true,
        TodoFilter.active => !todo.completed,
        TodoFilter.completed => todo.completed,
        TodoFilter.important => todo.important,
      };
}
