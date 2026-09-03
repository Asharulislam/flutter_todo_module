import 'package:dartz/dartz.dart';

import '../error/failure.dart';

/// Result of an async operation that can fail with a [Failure].
typedef ResultFuture<T> = Future<Either<Failure, T>>;

/// Same as [ResultFuture] but for operations with no meaningful success value.
typedef ResultVoid = ResultFuture<void>;

/// A decoded JSON object.
typedef DataMap = Map<String, dynamic>;
