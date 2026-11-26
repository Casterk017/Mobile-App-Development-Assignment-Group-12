import 'package:supabase_flutter/supabase_flutter.dart';

import '../database_config.dart';
import '../database_exception.dart';
import '../models/database_models.dart';

/// Authentication and student profile wrappers for the Flutter mobile app.
class AuthService {
  AuthService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _db => _client ?? DatabaseConfig.client;

  /// Stream of Supabase auth state transitions (signedIn, signedOut, tokenRefreshed, etc.).
  Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;

  /// Returns the currently authenticated Supabase user, or `null` if signed out.
  User? get currentUser => _db.auth.currentUser;

  /// Self-registers a new student account.
  ///
  /// The database trigger strictly enforces `role = 'user'` and `department = NULL`.
  Future<ProfileModel> signUpStudent({
    required String email,
    required String password,
    required String displayName,
    String? publicAlias,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanName = displayName.trim();
      final cleanAlias = (publicAlias ?? displayName).trim();

      final response = await _db.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'display_name': cleanName,
          'public_alias': cleanAlias,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const DatabaseException(
          code: 'signup_failed',
          message: 'Account could not be created.',
        );
      }

      final profile = await getCurrentProfile();
      if (profile == null) {
        throw const DatabaseException(
          code: 'profile_missing',
          message: 'Profile was not initialized for the new account.',
        );
      }
      return profile;
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'signup_failed');
    }
  }

  /// Signs in with email and password and returns the user's [ProfileModel].
  Future<ProfileModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _db.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final profile = await getCurrentProfile();
      if (profile == null) {
        throw const DatabaseException(
          code: 'profile_not_found',
          message: 'Signed in, but no profile record was found.',
        );
      }
      return profile;
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'signin_failed');
    }
  }

  /// Signs out the current user session.
  Future<void> signOut() async {
    try {
      await _db.auth.signOut();
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'signout_failed');
    }
  }

  /// Sends a password reset email without exposing credentials.
  Future<void> sendPasswordResetEmail(
    String email, {
    String? redirectTo,
  }) async {
    try {
      await _db.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: redirectTo,
      );
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'password_reset_failed');
    }
  }

  /// Loads the logged-in user's [ProfileModel], or returns `null` if signed out.
  Future<ProfileModel?> getCurrentProfile() async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return null;

      final data = await _db
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return null;
      return ProfileModel.fromJson(data);
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'fetch_profile_failed');
    }
  }

  /// Updates the logged-in user's [displayName] and/or privacy-safe [publicAlias].
  Future<ProfileModel> updateMyProfile({
    String? displayName,
    String? publicAlias,
  }) async {
    try {
      final userId = DatabaseConfig.requireCurrentUserId();
      final payload = <String, dynamic>{};

      if (displayName != null) {
        final trimmed = displayName.trim();
        if (trimmed.isEmpty || trimmed.length > 60) {
          throw const DatabaseException(
            code: 'invalid_display_name',
            message: 'Display name must be between 1 and 60 characters.',
          );
        }
        payload['display_name'] = trimmed;
      }

      if (publicAlias != null) {
        final trimmed = publicAlias.trim();
        if (trimmed.isEmpty || trimmed.length > 60) {
          throw const DatabaseException(
            code: 'invalid_public_alias',
            message: 'Public alias must be between 1 and 60 characters.',
          );
        }
        payload['public_alias'] = trimmed;
      }

      if (payload.isEmpty) {
        final existing = await getCurrentProfile();
        if (existing != null) return existing;
        throw const DatabaseException(
          code: 'profile_not_found',
          message: 'Profile not found.',
        );
      }

      final updated = await _db
          .from('profiles')
          .update(payload)
          .eq('id', userId)
          .select()
          .single();

      return ProfileModel.fromJson(updated);
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'update_profile_failed');
    }
  }
}
