/**
 * Typed exception thrown by all wrappers in `Website/src/Database/`.
 */
export class DatabaseException extends Error {
  public readonly code: string;
  public readonly cause?: unknown;

  constructor(code: string, message: string, cause?: unknown) {
    super(message);
    this.name = 'DatabaseException';
    this.code = code;
    this.cause = cause;
  }
}

export function throwMappedDatabaseError(
  error: unknown,
  fallbackCode = 'database_error',
): never {
  if (error instanceof DatabaseException) {
    throw error;
  }

  if (typeof error === 'object' && error !== null) {
    const rec = error as Record<string, unknown>;
    const code =
      typeof rec.code === 'string' && rec.code.length > 0
        ? rec.code
        : typeof rec.status === 'number'
          ? String(rec.status)
          : fallbackCode;
    const message =
      typeof rec.message === 'string' && rec.message.length > 0
        ? rec.message
        : 'An unexpected database error occurred.';
    throw new DatabaseException(code, message, error);
  }

  throw new DatabaseException(
    fallbackCode,
    typeof error === 'string' ? error : 'An unexpected database error occurred.',
    error,
  );
}
