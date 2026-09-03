import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/todo.dart';

/// [Todo] + JSON (de)serialisation. Kept in the data layer so the domain entity
/// stays free of transport concerns.
///
/// Parsing is deliberately lenient about key names and value types because the
/// exact API payload isn't pinned down yet – adjust the alternates once the
/// real contract is known.
class TodoModel extends Todo {
  const TodoModel({
    required super.id,
    required super.title,
    super.completed,
    super.important,
    super.createdAt,
    super.updatedAt,
  });

  factory TodoModel.fromJson(DataMap json) {
    return TodoModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      completed: _asBool(json['completed'] ?? json['isCompleted'] ?? json['done']),
      important: _asBool(json['important'] ?? json['isImportant']),
      createdAt: _asDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _asDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  factory TodoModel.fromEntity(Todo todo) {
    return TodoModel(
      id: todo.id,
      title: todo.title,
      completed: todo.completed,
      important: todo.important,
      createdAt: todo.createdAt,
      updatedAt: todo.updatedAt,
    );
  }

  DataMap toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
        'important': important,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
