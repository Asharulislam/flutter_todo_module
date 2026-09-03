import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom input row for creating a task, with an inline "important" toggle.
class AddTodoField extends StatefulWidget {
  const AddTodoField({
    super.key,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  final void Function(String title, {required bool important}) onSubmit;
  final bool isSubmitting;

  @override
  State<AddTodoField> createState() => _AddTodoFieldState();
}

class _AddTodoFieldState extends State<AddTodoField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _important = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSubmitting) return;
    widget.onSubmit(text, important: _important);
    _controller.clear();
    setState(() => _important = false);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.spaceLg,
            AppDimens.spaceSm,
            AppDimens.spaceSm,
            AppDimens.spaceSm,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: AppStrings.filterImportant,
                onPressed: () => setState(() => _important = !_important),
                icon: Icon(
                  _important ? Icons.star_rounded : Icons.star_border_rounded,
                  color: _important
                      ? AppColors.important
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    hintText: AppStrings.addTodoHint,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.spaceSm),
              _SendButton(
                isSubmitting: widget.isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isSubmitting, required this.onPressed});

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: isSubmitting ? null : onPressed,
      icon: isSubmitting
          ? const SizedBox.square(
              dimension: AppDimens.iconSm,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.arrow_upward_rounded),
    );
  }
}
