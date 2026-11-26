# Supabase Backend (`supabase/`)

Shared PostgreSQL schema, Row-Level Security (RLS) policies, Storage buckets, RPCs, Edge Function, and dummy seed script for the **Campus Safety & Incident Reporting System** (UTS Campus).

## 1. Apply SQL Migrations (in order)

Run the migrations via Supabase CLI (`supabase db push`) or paste them in order in the Supabase Dashboard **SQL Editor**:

1. `migrations/202611250001_core_schema.sql` — Tables, constraints, indexes, triggers (dynamic GPS verification from `campus_settings`, initial report timeline, automatic contribution points on resolution, chat sender snapshots).
2. `migrations/202611250002_rls_and_storage.sql` — Role helpers, RLS policies across all 12 tables, private `report-attachments` bucket, and public `pin-images` bucket.
3. `migrations/202611250003_rpcs_and_views.sql` — `get_pin_report_summaries`, `get_leaderboard` (Top 20 default), `get_my_rank`, `get_admin_dashboard_stats`, `get_or_create_department_chat`, `get_or_create_admin_super_admin_channel`, `update_report_status`.
4. `migrations/202611250004_seed_reference_data.sql` — Default UTS bounds (`campus_settings`), all 19 UTS preset pins, 6 initial `category_department_map` rows, and default `Campus Safety Circle` community channel.

## 2. Deploy the Super Admin Edge Function

```bash
supabase functions deploy admin-accounts
```

The function verifies the caller's JWT belongs to `role = 'super_admin'` and uses the server-side `SUPABASE_SERVICE_ROLE_KEY` to handle `list_accounts`, `create_admin`, `delete_account`, and `send_recovery_email`.

## 3. Seed Dummy Accounts & Sample Data

1. Install Website dependencies first (provides `@supabase/supabase-js`):
   ```bash
   cd Website && npm install && cd ..
   ```
2. Copy `supabase/.env.example` → `supabase/.env` and fill in `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`.
3. Run the idempotent seed script from the repo root:
   ```bash
   node --env-file=supabase/.env supabase/seed/seed.mjs
   ```

### Pre-Seeded Dummy Accounts (Default Password: `CampusSafe123!`)
- **Super Admin:** `superadmin@uts.edu.my`
- **Department Admins:** `facilities.admin@uts.edu.my`, `cleaner.admin@uts.edu.my`, `parking.admin@uts.edu.my`, `security.admin@uts.edu.my`
- **Students:** `fern@student.uts.edu.my`, `river@student.uts.edu.my`, `cedar@student.uts.edu.my`, `oak@student.uts.edu.my`, `iris@student.uts.edu.my`, `pine@student.uts.edu.my`
