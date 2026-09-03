import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/paginated_todos.dart';
import 'todo_model.dart';

/// [PaginatedTodos] + JSON parsing.
///
/// Handles the common `{ "data": [...], "meta": {...} }` envelope as well as a
/// few alternates (bare list, `items`/`todos`/`results`, `pagination` block) so
/// the UI keeps working whatever shape the API settles on.
class PaginatedTodosModel extends PaginatedTodos {
  const PaginatedTodosModel({
    required super.items,
    required super.page,
    required super.limit,
    required super.total,
    required super.totalPages,
  });

  factory PaginatedTodosModel.fromResponse(
    dynamic body, {
    required int requestedPage,
    required int requestedLimit,
  }) {
    // Bare list response: `[ {...}, {...} ]`
    if (body is List) {
      final items = _parseItems(body);
      return PaginatedTodosModel(
        items: items,
        page: requestedPage,
        limit: requestedLimit,
        total: items.length,
        totalPages: 1,
      );
    }

    final json = (body as DataMap?) ?? const {};
    final rawList = json['data'] ??
        json['items'] ??
        json['todos'] ??
        json['results'] ??
        const [];
    final items = _parseItems(rawList is List ? rawList : const []);

    final meta = (json['meta'] ?? json['pagination'] ?? json) as DataMap;

    return PaginatedTodosModel(
      items: items,
      page: _asInt(meta['page'] ?? meta['currentPage'], requestedPage),
      limit: _asInt(
        meta['limit'] ?? meta['perPage'] ?? meta['pageSize'],
        requestedLimit,
      ),
      total: _asInt(
        meta['total'] ?? meta['totalItems'] ?? meta['count'],
        items.length,
      ),
      totalPages: _asInt(
        meta['totalPages'] ?? meta['pageCount'] ?? meta['lastPage'],
        1,
      ),
    );
  }

  static List<TodoModel> _parseItems(List<dynamic> raw) {
    return raw
        .whereType<Map>()
        .map((e) => TodoModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
