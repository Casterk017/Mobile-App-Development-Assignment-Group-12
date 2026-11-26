import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database_exception.dart';

/// Central entry point for initializing Supabase in the Flutter mobile app.
///
/// Call `await DatabaseConfig.initialize();` once in `main()` before `runApp()`.
class DatabaseConfig {
  DatabaseConfig._();

  static bool _initialized = false;

  /// Loads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `.env` and initializes Supabase.
  static Future<void> initialize({String envFileName = '.env'}) async {
    if (_initialized) return;
    try {
      await dotenv.load(fileName: envFileName);
      final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
      final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

      if (url.isEmpty || anonKey.isEmpty) {
        throw const DatabaseException(
          code: 'missing_env',
          message:
              'SUPABASE_URL and SUPABASE_ANON_KEY must be set in Android/.env.',
        );
      }

      await initializeWithCredentials(url: url, anonKey: anonKey);
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'init_failed');
    }
  }

  /// Explicit initializer for tests or environments providing credentials directly.
  static Future<void> initializeWithCredentials({
    required String url,
    required String anonKey,
  }) async {
    if (_initialized) return;
    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _initialized = true;
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'init_failed');
    }
  }

  /// Returns the initialized [SupabaseClient].
  static SupabaseClient get client {
    if (!_initialized) {
      throw const DatabaseException(
        code: 'not_initialized',
        message: 'Call DatabaseConfig.initialize() before using Database services.',
      );
    }
    return Supabase.instance.client;
  }

  /// Convenience helper returning the authenticated user's UUID, or throwing if signed out.
  static String requireCurrentUserId() {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw const DatabaseException(
        code: 'unauthenticated',
        message: 'You must be signed in to perform this action.',
      );
    }
    return userId;
  }
}
