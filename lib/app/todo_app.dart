import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../di/injection_container.dart';
import '../features/todos/presentation/cubit/todo_cubit.dart';
import '../features/todos/presentation/pages/todos_page.dart';

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: BlocProvider<TodoCubit>(
        create: (_) => sl<TodoCubit>()..loadTodos(),
        child: const TodosPage(),
      ),
    );
  }
}
