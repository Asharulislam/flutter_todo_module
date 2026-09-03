import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../cubit/todo_filter.dart';

/// Horizontal row of choice chips for switching [TodoFilter].
class TodoFilterBar extends StatelessWidget {
  const TodoFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TodoFilter selected;
  final ValueChanged<TodoFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceLg),
        itemCount: TodoFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimens.spaceSm),
        itemBuilder: (context, index) {
          final filter = TodoFilter.values[index];
          return Center(
            child: ChoiceChip(
              label: Text(filter.label),
              selected: filter == selected,
              onSelected: (_) => onChanged(filter),
            ),
          );
        },
      ),
    );
  }
}
