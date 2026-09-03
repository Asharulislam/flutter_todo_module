import 'package:get_it/get_it.dart';

import '../core/network/auth_token_provider.dart';
import '../core/network/dio_client.dart';
import '../features/todos/data/datasources/todo_remote_data_source.dart';
import '../features/todos/data/repositories/todo_repository_impl.dart';
import '../features/todos/domain/repositories/todo_repository.dart';
import '../features/todos/domain/usecases/add_todo.dart';
import '../features/todos/domain/usecases/delete_todo.dart';
import '../features/todos/domain/usecases/get_todos.dart';
import '../features/todos/domain/usecases/set_todo_completion.dart';
import '../features/todos/domain/usecases/update_todo.dart';
import '../features/todos/presentation/cubit/todo_cubit.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Wires the object graph. Call once from `main()` before `runApp`.
Future<void> initDependencies() async {
  // ---------------------------------------------------------------------------
  // Core / infrastructure
  // ---------------------------------------------------------------------------
  // TODO: swap for the native-backed implementation once the Android token
  // bridge is available.
  sl.registerLazySingleton<AuthTokenProvider>(NoAuthTokenProvider.new);
  sl.registerLazySingleton<DioClient>(
    () => DioClient(tokenProvider: sl()),
  );

  // ---------------------------------------------------------------------------
  // Todos feature
  // ---------------------------------------------------------------------------
  sl
    ..registerLazySingleton<TodoRemoteDataSource>(
      () => TodoRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<TodoRepository>(
      () => TodoRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetTodos(sl()))
    ..registerLazySingleton(() => AddTodo(sl()))
    ..registerLazySingleton(() => UpdateTodo(sl()))
    ..registerLazySingleton(() => DeleteTodo(sl()))
    ..registerLazySingleton(() => SetTodoCompletion(sl()))
    ..registerFactory(
      () => TodoCubit(
        getTodos: sl(),
        addTodo: sl(),
        updateTodo: sl(),
        deleteTodo: sl(),
        setTodoCompletion: sl(),
      ),
    );
}
