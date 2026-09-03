// Unit tests for the Todos feature.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo/features/todos/presentation/cubit/todo_filter.dart';

void main() {
  group('TodoFilter query mapping', () {
    test('all → no query constraints', () {
      expect(TodoFilter.all.completedQuery, isNull);
      expect(TodoFilter.all.importantQuery, isNull);
    });

    test('active → completed=false', () {
      expect(TodoFilter.active.completedQuery, isFalse);
      expect(TodoFilter.active.importantQuery, isNull);
    });

    test('completed → completed=true', () {
      expect(TodoFilter.completed.completedQuery, isTrue);
      expect(TodoFilter.completed.importantQuery, isNull);
    });

    test('important → important=true', () {
      expect(TodoFilter.important.completedQuery, isNull);
      expect(TodoFilter.important.importantQuery, isTrue);
    });
  });
}
