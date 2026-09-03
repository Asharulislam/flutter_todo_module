/// User-facing copy. Keeping it here keeps widgets free of magic strings and
/// makes localisation a single-file change later.
class AppStrings {
  const AppStrings._();

  static const String appName = 'Todos';

  // Screen
  static const String todosTitle = 'Todos';
  static const String addTodoHint = 'Add a task…';
  static const String editTodoTitle = 'Edit task';
  static const String editTodoHint = 'Task title';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String retry = 'Retry';

  // Filters
  static const String filterAll = 'All';
  static const String filterActive = 'Active';
  static const String filterCompleted = 'Completed';
  static const String filterImportant = 'Important';

  // Empty / error states
  static const String emptyTitle = 'Nothing here yet';
  static const String emptySubtitle = 'Add your first task to get started.';
  static const String errorTitle = 'Couldn\'t load your tasks';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection.';

  // Confirmations
  static const String deleteTodoConfirmTitle = 'Delete task?';
  static const String deleteTodoConfirmMessage =
      'This task will be permanently removed.';
}
