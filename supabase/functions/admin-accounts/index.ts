// Supabase Edge Function: admin-accounts
// Privileged Super Admin account management using server-side SUPABASE_SERVICE_ROLE_KEY.
// Deploy with: supabase functions deploy admin-accounts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const VALID_DEPARTMENTS = new Set(['facilities', 'cleaner', 'parking', 'security']);

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed', message: 'Use POST.' }, 405);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');

  if (!supabaseUrl || !serviceRoleKey || !anonKey) {
    return jsonResponse(
      { error: 'server_misconfigured', message: 'Missing Supabase environment variables.' },
      500,
    );
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return jsonResponse({ error: 'unauthorized', message: 'Missing bearer token.' }, 401);
  }

  // Verify caller JWT with user-scoped client
  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user: caller },
    error: authError,
  } = await callerClient.auth.getUser();

  if (authError || !caller) {
    return jsonResponse({ error: 'unauthorized', message: 'Invalid or expired session.' }, 401);
  }

  // Privileged client (server-side only)
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // Verify caller is super_admin
  const { data: callerProfile, error: profileError } = await adminClient
    .from('profiles')
    .select('id, role')
    .eq('id', caller.id)
    .single();

  if (profileError || callerProfile?.role !== 'super_admin') {
    return jsonResponse(
      { error: 'forbidden', message: 'Super Admin privileges are required.' },
      403,
    );
  }

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: 'invalid_json', message: 'Request body must be valid JSON.' }, 400);
  }

  const action = String(payload.action ?? '');

  try {
    switch (action) {
      case 'list_accounts': {
        const { data: profiles, error } = await adminClient
          .from('profiles')
          .select('id, email, display_name, public_alias, role, department, created_at, updated_at')
          .order('created_at', { ascending: false });

        if (error) throw error;
        return jsonResponse({ accounts: profiles ?? [] });
      }

      case 'create_admin': {
        const email = String(payload.email ?? '').trim().toLowerCase();
        const password = String(payload.password ?? '');
        const displayName = String(payload.displayName ?? '').trim();
        const publicAlias = String(payload.publicAlias ?? displayName).trim();
        const department = String(payload.department ?? '').trim();

        if (!email || !password || password.length < 8) {
          return jsonResponse(
            { error: 'validation_error', message: 'Valid email and password (min 8 chars) are required.' },
            400,
          );
        }
        if (!displayName || displayName.length > 60) {
          return jsonResponse(
            { error: 'validation_error', message: 'Display name must be 1-60 characters.' },
            400,
          );
        }
        if (!VALID_DEPARTMENTS.has(department)) {
          return jsonResponse(
            { error: 'validation_error', message: 'Department must be facilities, cleaner, parking, or security.' },
            400,
          );
        }

        const { data: created, error: createError } = await adminClient.auth.admin.createUser({
          email,
          password,
          email_confirm: true,
          app_metadata: { role: 'admin', department },
          user_metadata: { display_name: displayName, public_alias: publicAlias },
        });

        if (createError || !created.user) {
          return jsonResponse(
            { error: 'create_failed', message: createError?.message ?? 'Could not create admin account.' },
            400,
          );
        }

        // Fetch synced profile row created by handle_new_user trigger
        const { data: profile, error: fetchError } = await adminClient
          .from('profiles')
          .select('id, email, display_name, public_alias, role, department, created_at, updated_at')
          .eq('id', created.user.id)
          .single();

        if (fetchError) throw fetchError;
        return jsonResponse({ account: profile }, 201);
      }

      case 'delete_account': {
        const userId = String(payload.userId ?? '').trim();
        if (!userId) {
          return jsonResponse({ error: 'validation_error', message: 'userId is required.' }, 400);
        }
        if (userId === caller.id) {
          return jsonResponse(
            { error: 'self_delete_forbidden', message: 'Super Admin cannot delete their own account.' },
            400,
          );
        }

        const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId);
        if (deleteError) {
          return jsonResponse(
            { error: 'delete_failed', message: deleteError.message },
            400,
          );
        }

        return jsonResponse({ deletedUserId: userId });
      }

      case 'send_recovery_email': {
        const email = String(payload.email ?? '').trim().toLowerCase();
        const redirectTo = payload.redirectTo ? String(payload.redirectTo) : undefined;

        if (!email) {
          return jsonResponse({ error: 'validation_error', message: 'email is required.' }, 400);
        }

        // Sends a password recovery email via Supabase Auth without exposing passwords.
        const { error: resetError } = await adminClient.auth.resetPasswordForEmail(email, {
          redirectTo,
        });

        if (resetError) {
          return jsonResponse(
            { error: 'recovery_failed', message: resetError.message },
            400,
          );
        }

        return jsonResponse({ sentTo: email });
      }

      default:
        return jsonResponse(
          { error: 'unknown_action', message: `Unsupported action: ${action}` },
          400,
        );
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unexpected server error.';
    return jsonResponse({ error: 'internal_error', message }, 500);
  }
});
