import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { DatabaseException } from './errors';

let cachedClient: SupabaseClient | null = null;

export interface DatabaseInitOptions {
  url: string;
  anonKey: string;
}

/**
 * Optional explicit initializer (useful for tests or non-Vite setups).
 * In Vite apps, calling `getSupabaseClient()` automatically reads
 * `import.meta.env.VITE_SUPABASE_URL` and `import.meta.env.VITE_SUPABASE_ANON_KEY`.
 */
export function initDatabase(options: DatabaseInitOptions): SupabaseClient {
  const url = options.url.trim();
  const anonKey = options.anonKey.trim();
  if (!url || !anonKey) {
    throw new DatabaseException(
      'missing_env',
      'VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY are required.',
    );
  }
  cachedClient = createClient(url, anonKey);
  return cachedClient;
}

export function getSupabaseClient(): SupabaseClient {
  if (cachedClient) return cachedClient;

  const url = (import.meta.env?.VITE_SUPABASE_URL ?? '').trim();
  const anonKey = (import.meta.env?.VITE_SUPABASE_ANON_KEY ?? '').trim();

  if (!url || !anonKey) {
    throw new DatabaseException(
      'missing_env',
      'Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY in Website/.env.',
    );
  }

  cachedClient = createClient(url, anonKey);
  return cachedClient;
}
