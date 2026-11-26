import type { AuthChangeEvent, Session } from '@supabase/supabase-js';
import { getSupabaseClient } from '../client';
import { DatabaseException, throwMappedDatabaseError } from '../errors';
import type { AdminDepartment, Profile, UserRole } from '../types';

function mapProfile(row: Record<string, unknown>): Profile {
  return {
    id: String(row.id),
    email: String(row.email),
    displayName: String(row.display_name),
    publicAlias: String(row.public_alias),
    role: row.role as UserRole,
    department: (row.department as AdminDepartment | null) ?? null,
    createdAt: String(row.created_at),
    updatedAt: String(row.updated_at),
  };
}

/**
 * Signs in an administrator (`admin` or `super_admin`) to the Web Admin Portal.
 * Regular mobile students (`role = 'user'`) are immediately signed out and rejected.
 */
export async function signInAdmin(email: string, password: string): Promise<Profile> {
  try {
    const supabase = getSupabaseClient();
    const { data, error } = await supabase.auth.signInWithPassword({
      email: email.trim().toLowerCase(),
      password,
    });
    if (error || !data.user) {
      throw error ?? new DatabaseException('auth_error', 'Sign-in failed.');
    }

    const profile = await getCurrentProfile();
    if (!profile) {
      await supabase.auth.signOut();
      throw new DatabaseException('profile_not_found', 'Account profile not found.');
    }

    if (profile.role !== 'admin' && profile.role !== 'super_admin') {
      await supabase.auth.signOut();
      throw new DatabaseException(
        'forbidden_portal_access',
        'Student accounts cannot access the Admin Web Portal.',
      );
    }

    return profile;
  } catch (err) {
    throwMappedDatabaseError(err, 'signin_failed');
  }
}

export async function signOut(): Promise<void> {
  try {
    const { error } = await getSupabaseClient().auth.signOut();
    if (error) throw error;
  } catch (err) {
    throwMappedDatabaseError(err, 'signout_failed');
  }
}

export async function getCurrentProfile(): Promise<Profile | null> {
  try {
    const supabase = getSupabaseClient();
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();
    if (authError || !user) return null;

    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .maybeSingle();

    if (error) throw error;
    return data ? mapProfile(data as Record<string, unknown>) : null;
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_profile_failed');
  }
}

export async function requestPasswordReset(
  email: string,
  redirectTo?: string,
): Promise<void> {
  try {
    const { error } = await getSupabaseClient().auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo ? { redirectTo } : undefined,
    );
    if (error) throw error;
  } catch (err) {
    throwMappedDatabaseError(err, 'password_reset_failed');
  }
}

export function onAuthStateChange(
  callback: (event: AuthChangeEvent, session: Session | null) => void,
): () => void {
  const {
    data: { subscription },
  } = getSupabaseClient().auth.onAuthStateChange(callback);
  return () => subscription.unsubscribe();
}
