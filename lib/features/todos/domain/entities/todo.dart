import 'package:equatable/equatable.dart';

/// Core business object for a task. Immutable; UI/state mutate via [copyWith].
class Todo extends Equatable {
  const Todo({
    required this.id,
    required this.title,
    this.completed = false,
    this.important = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final bool completed;
  final bool important;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Todo copyWith({
    String? id,
    String? title,
    bool? completed,
    bool? important,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      important: important ?? this.important,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, completed, important, createdAt, updatedAt];
}
