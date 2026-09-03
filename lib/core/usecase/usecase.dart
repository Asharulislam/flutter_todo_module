import 'package:equatable/equatable.dart';

import '../utils/typedefs.dart';

/// Base contract for every use case: a single callable unit of business logic
/// that takes [P] params and returns a [ResultFuture] of [T].
abstract class UseCase<T, P> {
  const UseCase();

  ResultFuture<T> call(P params);
}

/// Marker for use cases that need no input.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
