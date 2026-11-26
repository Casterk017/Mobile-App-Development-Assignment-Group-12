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

async function invokeAdminAccounts<T>(body: Record<string, unknown>): Promise<T> {
  const { data, error } = await getSupabaseClient().functions.invoke('admin-accounts', {
    body,
  });

  if (error) {
    throw new DatabaseException('edge_function_error', error.message, error);
  }
  if (data && typeof data === 'object' && 'error' in data) {
    const rec = data as Record<string, unknown>;
    throw new DatabaseException(
      String(rec.error),
      String(rec.message ?? 'Admin account operation failed.'),
      data,
    );
  }
  return data as T;
}

export interface CreateAdminAccountInput {
  email: string;
  password: string;
  displayName: string;
  publicAlias?: string;
  department: AdminDepartment;
}

/**
 * Super Admin: Lists all student, admin, and super_admin accounts via `admin-accounts` Edge Function.
 */
export async function listAllAccounts(): Promise<Profile[]> {
  try {
    const res = await invokeAdminAccounts<{ accounts: Record<string, unknown>[] }>({
      action: 'list_accounts',
    });
    return (res.accounts ?? []).map(mapProfile);
  } catch (err) {
    throwMappedDatabaseError(err, 'list_accounts_failed');
  }
}

/**
 * Super Admin: Creates a new regular department admin account (`facilities`, `cleaner`, `parking`, `security`).
 */
export async function createAdminAccount(
  input: CreateAdminAccountInput,
): Promise<Profile> {
  try {
    const res = await invokeAdminAccounts<{ account: Record<string, unknown> }>({
      action: 'create_admin',
      email: input.email.trim().toLowerCase(),
      password: input.password,
      displayName: input.displayName.trim(),
      publicAlias: (input.publicAlias ?? input.displayName).trim(),
      department: input.department,
    });
    return mapProfile(res.account);
  } catch (err) {
    throwMappedDatabaseError(err, 'create_admin_failed');
  }
}

/**
 * Super Admin: Hard-deletes a user or admin account via `auth.admin.deleteUser` (server-side).
 * Historical reports & chat messages remain intact via `ON DELETE SET NULL`.
 */
export async function deleteAccount(userId: string): Promise<string> {
  try {
    const res = await invokeAdminAccounts<{ deletedUserId: string }>({
      action: 'delete_account',
      userId,
    });
    return res.deletedUserId;
  } catch (err) {
    throwMappedDatabaseError(err, 'delete_account_failed');
  }
}

/**
 * Super Admin: Sends a privacy-preserving password recovery email without ever viewing or exposing passwords.
 */
export async function sendAccountRecoveryEmail(
  email: string,
  redirectTo?: string,
): Promise<string> {
  try {
    const res = await invokeAdminAccounts<{ sentTo: string }>({
      action: 'send_recovery_email',
      email: email.trim().toLowerCase(),
      ...(redirectTo ? { redirectTo } : {}),
    });
    return res.sentTo;
  } catch (err) {
    throwMappedDatabaseError(err, 'send_recovery_email_failed');
  }
}
