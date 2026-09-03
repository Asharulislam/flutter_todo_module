import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/todo.dart';

/// One row in the todo list: completion checkbox, title, important toggle and a
/// delete action. Purely presentational – all behaviour is delegated upward.
class TodoListTile extends StatelessWidget {
  const TodoListTile({
    super.key,
    required this.todo,
    required this.onToggleCompleted,
    required this.onToggleImportant,
    required this.onEdit,
    required this.onDelete,
    this.enabled = true,
  });

  final Todo todo;
  final ValueChanged<Todo> onToggleCompleted;
  final ValueChanged<Todo> onToggleImportant;
  final ValueChanged<Todo> onEdit;
  final ValueChanged<Todo> onDelete;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.only(
          left: AppDimens.spaceSm,
          right: AppDimens.spaceXs,
        ),
        enabled: enabled,
        onTap: enabled ? () => onEdit(todo) : null,
        leading: Checkbox(
          value: todo.completed,
          onChanged:
              enabled ? (_) => onToggleCompleted(todo) : null,
        ),
        title: Text(
          todo.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            decoration:
                todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed
                ? theme.colorScheme.onSurfaceVariant
                : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Important',
              onPressed: enabled ? () => onToggleImportant(todo) : null,
              icon: Icon(
                todo.important
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: todo.important
                    ? AppColors.important
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: enabled ? () => onDelete(todo) : null,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
