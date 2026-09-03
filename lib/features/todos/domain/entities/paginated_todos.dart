import 'package:equatable/equatable.dart';

import 'todo.dart';

/// One page of todos plus the paging metadata needed to fetch the next one.
class PaginatedTodos extends Equatable {
  const PaginatedTodos({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<Todo> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  /// Whether another page exists after the current one.
  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}
