import 'package:supabase_flutter/supabase_flutter.dart';

/// Typed exception thrown by all wrappers in `Android/lib/Database/`.
///
/// Teammates can catch [DatabaseException] in ViewModels and Repositories to
/// inspect [code] (machine-readable) and display [message] (user-friendly).
class DatabaseException implements Exception {
  const DatabaseException({
    required this.code,
    required this.message,
    this.cause,
  });

  final String code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'DatabaseException($code): $message';
}

/// Converts Supabase / network exceptions into a consistent [DatabaseException].
Never throwMappedDatabaseError(Object error, {String fallbackCode = 'database_error'}) {
  if (error is DatabaseException) {
    throw error;
  }
  if (error is AuthException) {
    throw DatabaseException(
      code: error.code ?? 'auth_error',
      message: error.message,
      cause: error,
    );
  }
  if (error is PostgrestException) {
    throw DatabaseException(
      code: error.code ?? 'postgrest_error',
      message: error.message,
      cause: error,
    );
  }
  if (error is StorageException) {
    throw DatabaseException(
      code: error.statusCode ?? 'storage_error',
      message: error.message,
      cause: error,
    );
  }
  throw DatabaseException(
    code: fallbackCode,
    message: error.toString(),
    cause: error,
  );
}
