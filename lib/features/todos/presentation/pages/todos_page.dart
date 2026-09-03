import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_message_view.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../domain/entities/todo.dart';
import '../cubit/todo_cubit.dart';
import '../widgets/add_todo_field.dart';
import '../widgets/edit_todo_dialog.dart';
import '../widgets/todo_filter_bar.dart';
import '../widgets/todo_list_tile.dart';

/// Screen that exercises every `/todos` endpoint:
/// list + paginate + filter (GET), create (POST), rename / toggle important
/// (PATCH), toggle completed (PATCH `/complete`) and delete (DELETE).
class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      context.read<TodoCubit>().loadMore();
    }
  }

  Future<void> _confirmDelete(Todo todo) async {
    final cubit = context.read<TodoCubit>();
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.deleteTodoConfirmTitle,
      message: AppStrings.deleteTodoConfirmMessage,
    );
    if (confirmed) {
      await cubit.deleteTodo(todo.id);
    }
  }

  Future<void> _edit(Todo todo) async {
    final cubit = context.read<TodoCubit>();
    final newTitle = await EditTodoDialog.show(context, todo.title);
    if (newTitle != null) {
      await cubit.editTitle(todo.id, newTitle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.todosTitle)),
      body: BlocConsumer<TodoCubit, TodoState>(
        listenWhen: (prev, curr) =>
            curr.actionError != null && prev.actionError != curr.actionError,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.actionError!)));
        },
        builder: (context, state) {
          return Column(
            children: [
              const SizedBox(height: AppDimens.spaceSm),
              TodoFilterBar(
                selected: state.filter,
                onChanged: context.read<TodoCubit>().changeFilter,
              ),
              const SizedBox(height: AppDimens.spaceSm),
              Expanded(child: _TodosBody(state: state, onEdit: _edit, onDelete: _confirmDelete, scrollController: _scrollController)),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<TodoCubit, TodoState>(
        buildWhen: (prev, curr) => prev.isMutating != curr.isMutating,
        builder: (context, state) {
          return AddTodoField(
            isSubmitting: state.isMutating,
            onSubmit: (title, {required important}) => context
                .read<TodoCubit>()
                .addTodo(title, important: important),
          );
        },
      ),
    );
  }
}

class _TodosBody extends StatelessWidget {
  const _TodosBody({
    required this.state,
    required this.onEdit,
    required this.onDelete,
    required this.scrollController,
  });

  final TodoState state;
  final ValueChanged<Todo> onEdit;
  final ValueChanged<Todo> onDelete;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TodoCubit>();

    if (state.isInitialLoading) {
      return const AppLoader();
    }

    if (state.status == TodoStatus.failure && state.todos.isEmpty) {
      return AppMessageView(
        icon: Icons.cloud_off_rounded,
        title: AppStrings.errorTitle,
        message: state.errorMessage ?? AppStrings.genericError,
        actionLabel: AppStrings.retry,
        onAction: cubit.refresh,
      );
    }

    if (state.todos.isEmpty) {
      return RefreshIndicator(
        onRefresh: cubit.refresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            AppMessageView(
              icon: Icons.checklist_rounded,
              title: AppStrings.emptyTitle,
              message: AppStrings.emptySubtitle,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.spaceLg,
          AppDimens.spaceXs,
          AppDimens.spaceLg,
          AppDimens.listBottomInset,
        ),
        itemCount: state.todos.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppDimens.spaceSm),
        itemBuilder: (context, index) {
          if (index >= state.todos.length) {
            return const Padding(
              padding: EdgeInsets.all(AppDimens.spaceLg),
              child: Center(child: CircularProgressIndicator.adaptive()),
            );
          }
          final todo = state.todos[index];
          return TodoListTile(
            todo: todo,
            enabled: !state.isMutating,
            onToggleCompleted: cubit.toggleCompleted,
            onToggleImportant: cubit.toggleImportant,
            onEdit: onEdit,
            onDelete: onDelete,
          );
        },
      ),
    );
  }
}
