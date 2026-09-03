import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

/// Simple single-field dialog for renaming a task. Returns the new title, or
/// `null` if dismissed / unchanged.
class EditTodoDialog extends StatefulWidget {
  const EditTodoDialog({super.key, required this.initialTitle});

  final String initialTitle;

  static Future<String?> show(BuildContext context, String initialTitle) {
    return showDialog<String>(
      context: context,
      builder: (_) => EditTodoDialog(initialTitle: initialTitle),
    );
  }

  @override
  State<EditTodoDialog> createState() => _EditTodoDialogState();
}

class _EditTodoDialogState extends State<EditTodoDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialTitle);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    Navigator.of(context).pop(
      text.isEmpty || text == widget.initialTitle ? null : text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.editTodoTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(hintText: AppStrings.editTodoHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(onPressed: _save, child: const Text(AppStrings.save)),
      ],
    );
  }
}
