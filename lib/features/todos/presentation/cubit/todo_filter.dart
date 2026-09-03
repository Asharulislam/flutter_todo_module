import '../../../../core/constants/app_strings.dart';

/// The list filter the user can toggle between. Maps to the
/// `completed` / `important` query params on `GET /todos`.
enum TodoFilter {
  all(AppStrings.filterAll),
  active(AppStrings.filterActive),
  completed(AppStrings.filterCompleted),
  important(AppStrings.filterImportant);

  const TodoFilter(this.label);

  final String label;

  bool? get completedQuery => switch (this) {
        TodoFilter.active => false,
        TodoFilter.completed => true,
        TodoFilter.all || TodoFilter.important => null,
      };

  bool? get importantQuery => this == TodoFilter.important ? true : null;
}
