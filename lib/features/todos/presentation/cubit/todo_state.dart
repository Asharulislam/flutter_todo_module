part of 'todo_cubit.dart';

enum TodoStatus { initial, loading, success, failure }

/// Single immutable snapshot of the Todos screen.
class TodoState extends Equatable {
  const TodoState({
    this.status = TodoStatus.initial,
    this.todos = const [],
    this.filter = TodoFilter.all,
    this.page = ApiConstants.defaultPage,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.isMutating = false,
    this.errorMessage,
    this.actionError,
  });

  /// Lifecycle of the primary list load.
  final TodoStatus status;
  final List<Todo> todos;
  final TodoFilter filter;

  /// Last page currently held in [todos].
  final int page;
  final int totalPages;

  /// A `loadMore()` request is in flight.
  final bool isLoadingMore;

  /// A create / update / delete request is in flight.
  final bool isMutating;

  /// Message for a failed list load (shown as a full-screen error).
  final String? errorMessage;

  /// One-shot message for a failed mutation (shown as a snackbar).
  final String? actionError;

  bool get hasMore => page < totalPages;

  bool get isInitialLoading =>
      status == TodoStatus.loading && todos.isEmpty;

  TodoState copyWith({
    TodoStatus? status,
    List<Todo>? todos,
    TodoFilter? filter,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    bool? isMutating,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return TodoState(
      status: status ?? this.status,
      todos: todos ?? this.todos,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        todos,
        filter,
        page,
        totalPages,
        isLoadingMore,
        isMutating,
        errorMessage,
        actionError,
      ];
}
