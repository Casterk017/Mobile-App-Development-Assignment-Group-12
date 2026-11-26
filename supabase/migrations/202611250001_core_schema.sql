-- ============================================================================
-- Migration 0001: Core Schema, Constraints, Indexes, and Triggers
-- Campus Safety & Incident Reporting System (UTS Campus)
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ----------------------------------------------------------------------------
-- 1. Profiles (1-to-1 with auth.users)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL CHECK (char_length(trim(display_name)) BETWEEN 1 AND 60),
  public_alias TEXT NOT NULL CHECK (char_length(trim(public_alias)) BETWEEN 1 AND 60),
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin', 'super_admin')),
  department TEXT CHECK (department IN ('facilities', 'cleaner', 'parking', 'security')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_profiles_role_department CHECK (
    (role = 'admin' AND department IS NOT NULL)
    OR (role IN ('user', 'super_admin') AND department IS NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_department ON public.profiles(department) WHERE department IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 2. Campus Settings (Singleton expandable GPS bounds for UTS campus)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.campus_settings (
  id TEXT PRIMARY KEY DEFAULT 'default' CHECK (id = 'default'),
  min_lat DOUBLE PRECISION NOT NULL,
  max_lat DOUBLE PRECISION NOT NULL,
  min_lng DOUBLE PRECISION NOT NULL,
  max_lng DOUBLE PRECISION NOT NULL,
  updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_campus_bounds_valid CHECK (min_lat < max_lat AND min_lng < max_lng)
);

-- ----------------------------------------------------------------------------
-- 3. Preset Campus Pins
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.preset_pins (
  id TEXT PRIMARY KEY,
  block_name TEXT NOT NULL CHECK (char_length(trim(block_name)) BETWEEN 1 AND 120),
  section_title TEXT NOT NULL CHECK (char_length(trim(section_title)) BETWEEN 1 AND 80),
  description TEXT NOT NULL,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  image_urls TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 4. Dynamic Category -> Admin Department Mapping
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.category_department_map (
  category_key TEXT PRIMARY KEY CHECK (category_key ~ '^[a-z0-9_]+$'),
  display_label TEXT NOT NULL CHECK (char_length(trim(display_label)) BETWEEN 1 AND 80),
  department TEXT NOT NULL CHECK (department IN ('facilities', 'cleaner', 'parking', 'security')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_category_dept_active ON public.category_department_map(is_active, department);

-- ----------------------------------------------------------------------------
-- 5. Incident Reports & Status Timeline
-- ----------------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS public.report_code_seq START WITH 1001 INCREMENT BY 1;

CREATE TABLE IF NOT EXISTS public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_code TEXT NOT NULL UNIQUE,
  reporter_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  pin_id TEXT REFERENCES public.preset_pins(id) ON DELETE SET NULL,
  category_key TEXT NOT NULL REFERENCES public.category_department_map(category_key) ON DELETE RESTRICT,
  title TEXT NOT NULL CHECK (char_length(trim(title)) BETWEEN 1 AND 120),
  location TEXT NOT NULL CHECK (char_length(trim(location)) BETWEEN 1 AND 200),
  description TEXT NOT NULL CHECK (char_length(trim(description)) BETWEEN 1 AND 2000),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'rejected')),
  reporter_lat DOUBLE PRECISION,
  reporter_lng DOUBLE PRECISION,
  is_gps_verified BOOLEAN NOT NULL DEFAULT false,
  attachment_paths TEXT[] NOT NULL DEFAULT '{}',
  resolved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reports_reporter_created ON public.reports(reporter_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_category_created ON public.reports(category_key, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_status_created ON public.reports(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_pin_id ON public.reports(pin_id) WHERE pin_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.report_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
  actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'in_progress', 'resolved', 'rejected')),
  note TEXT NOT NULL CHECK (char_length(trim(note)) BETWEEN 1 AND 1000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_report_updates_report_created ON public.report_updates(report_id, created_at ASC);

-- ----------------------------------------------------------------------------
-- 6. Append-Only Contribution Points Ledger
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.contribution_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  report_id UUID REFERENCES public.reports(id) ON DELETE SET NULL,
  points INTEGER NOT NULL CHECK (points > 0),
  reason TEXT NOT NULL CHECK (reason IN ('report_resolved_reporter', 'report_resolved_admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_contribution_event_once UNIQUE (report_id, profile_id, reason)
);

CREATE INDEX IF NOT EXISTS idx_contribution_events_profile_created ON public.contribution_events(profile_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_contribution_events_created ON public.contribution_events(created_at DESC);

-- ----------------------------------------------------------------------------
-- 7. Unified Chat System (Community + Student-Department + Admin-SuperAdmin)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL CHECK (type IN ('community', 'user_admin', 'admin_super_admin')),
  name TEXT,
  department TEXT CHECK (department IN ('facilities', 'cleaner', 'parking', 'security')),
  student_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_chat_channel_shape CHECK (
    (type = 'user_admin' AND department IS NOT NULL)
    OR (type <> 'user_admin' AND department IS NULL AND student_id IS NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_channels_student_department
  ON public.chat_channels(student_id, department)
  WHERE type = 'user_admin' AND student_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_chat_channels_type_dept ON public.chat_channels(type, department);

CREATE TABLE IF NOT EXISTS public.chat_channel_members (
  channel_id UUID NOT NULL REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (channel_id, profile_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_channel_members_profile ON public.chat_channel_members(profile_id);

CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  sender_alias_snapshot TEXT NOT NULL DEFAULT 'Campus Member',
  sender_role_snapshot TEXT NOT NULL DEFAULT 'user' CHECK (sender_role_snapshot IN ('user', 'admin', 'super_admin')),
  body TEXT NOT NULL CHECK (char_length(trim(body)) BETWEEN 1 AND 1000),
  sent_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_channel_sent ON public.chat_messages(channel_id, sent_at ASC);

CREATE TABLE IF NOT EXISTS public.chat_message_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
  reporter_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  reason TEXT NOT NULL DEFAULT 'inappropriate' CHECK (char_length(trim(reason)) BETWEEN 1 AND 500),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'reviewed', 'dismissed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chat_message_reports_status ON public.chat_message_reports(status, created_at DESC);

CREATE TABLE IF NOT EXISTS public.chat_blocked_users (
  blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (blocker_id, blocked_id),
  CONSTRAINT chk_not_self_block CHECK (blocker_id <> blocked_id)
);

-- ============================================================================
-- Triggers & Server-Side Business Logic
-- ============================================================================

-- 1) Auto-create profile when a new auth.users record is created.
--    Self-registration is strictly locked to role = 'user', department = NULL.
--    Only service_role (Edge Function / seed script) via raw_app_meta_data can set admin/super_admin.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT := 'user';
  v_department TEXT := NULL;
  v_display_name TEXT;
  v_public_alias TEXT;
BEGIN
  IF NEW.raw_app_meta_data ? 'role'
     AND (NEW.raw_app_meta_data->>'role') IN ('user', 'admin', 'super_admin') THEN
    v_role := NEW.raw_app_meta_data->>'role';
  END IF;

  IF v_role = 'admin' THEN
    v_department := NEW.raw_app_meta_data->>'department';
    IF v_department IS NULL OR v_department NOT IN ('facilities', 'cleaner', 'parking', 'security') THEN
      RAISE EXCEPTION 'Admin account requires a valid department (facilities, cleaner, parking, security).';
    END IF;
  ELSE
    v_department := NULL;
  END IF;

  v_display_name := COALESCE(
    NULLIF(trim(NEW.raw_user_meta_data->>'display_name'), ''),
    split_part(COALESCE(NEW.email, 'Campus User'), '@', 1)
  );
  v_public_alias := COALESCE(
    NULLIF(trim(NEW.raw_user_meta_data->>'public_alias'), ''),
    v_display_name
  );

  INSERT INTO public.profiles (id, email, display_name, public_alias, role, department)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, NEW.id::text || '@unknown.local'),
    left(v_display_name, 60),
    left(v_public_alias, 60),
    v_role,
    v_department
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2) Prevent non-super-admins from escalating role/department on profiles update.
CREATE OR REPLACE FUNCTION public.trg_profiles_before_update_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role TEXT;
BEGIN
  NEW.updated_at := now();

  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  SELECT role INTO v_caller_role FROM public.profiles WHERE id = auth.uid();

  IF COALESCE(v_caller_role, 'user') <> 'super_admin' THEN
    IF NEW.role IS DISTINCT FROM OLD.role OR NEW.department IS DISTINCT FROM OLD.department OR NEW.email IS DISTINCT FROM OLD.email THEN
      RAISE EXCEPTION 'Insufficient privileges to modify role, department, or email.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_before_update ON public.profiles;
CREATE TRIGGER trg_profiles_before_update
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.trg_profiles_before_update_fn();

-- 3) Track updated_at / updated_by on campus_settings & preset_pins.
CREATE OR REPLACE FUNCTION public.trg_campus_settings_before_update_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  IF auth.uid() IS NOT NULL THEN
    NEW.updated_by := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_campus_settings_before_update ON public.campus_settings;
CREATE TRIGGER trg_campus_settings_before_update
  BEFORE UPDATE ON public.campus_settings
  FOR EACH ROW EXECUTE FUNCTION public.trg_campus_settings_before_update_fn();

CREATE OR REPLACE FUNCTION public.trg_preset_pins_before_update_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_preset_pins_before_update ON public.preset_pins;
CREATE TRIGGER trg_preset_pins_before_update
  BEFORE UPDATE ON public.preset_pins
  FOR EACH ROW EXECUTE FUNCTION public.trg_preset_pins_before_update_fn();

-- 4) Reports BEFORE INSERT: assign report_code, enforce initial status, verify GPS against campus_settings.
CREATE OR REPLACE FUNCTION public.trg_reports_before_insert_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_bounds RECORD;
BEGIN
  IF NEW.report_code IS NULL OR trim(NEW.report_code) = '' THEN
    NEW.report_code := 'UTS-' || nextval('public.report_code_seq')::TEXT;
  END IF;

  IF auth.role() <> 'service_role' THEN
    NEW.reporter_id := auth.uid();
    NEW.status := 'pending';
    NEW.resolved_by := NULL;
    NEW.resolved_at := NULL;
  END IF;

  NEW.submitted_at := COALESCE(NEW.submitted_at, now());
  NEW.updated_at := now();

  -- Compute GPS verification dynamically from campus_settings (never trust client flag).
  NEW.is_gps_verified := false;
  IF NEW.reporter_lat IS NOT NULL AND NEW.reporter_lng IS NOT NULL THEN
    SELECT min_lat, max_lat, min_lng, max_lng
      INTO v_bounds
      FROM public.campus_settings
     WHERE id = 'default';

    IF FOUND
       AND NEW.reporter_lat BETWEEN v_bounds.min_lat AND v_bounds.max_lat
       AND NEW.reporter_lng BETWEEN v_bounds.min_lng AND v_bounds.max_lng THEN
      NEW.is_gps_verified := true;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reports_before_insert ON public.reports;
CREATE TRIGGER trg_reports_before_insert
  BEFORE INSERT ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.trg_reports_before_insert_fn();

-- 5) Reports AFTER INSERT: create initial timeline entry.
CREATE OR REPLACE FUNCTION public.trg_reports_after_insert_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.report_updates (report_id, actor_id, status, note, created_at)
  VALUES (
    NEW.id,
    NEW.reporter_id,
    NEW.status,
    'Report received for review.',
    NEW.submitted_at
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reports_after_insert ON public.reports;
CREATE TRIGGER trg_reports_after_insert
  AFTER INSERT ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.trg_reports_after_insert_fn();

-- 6) Reports BEFORE UPDATE: protect server fields & stamp resolved metadata.
CREATE OR REPLACE FUNCTION public.trg_reports_before_update_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at := now();

  IF auth.role() <> 'service_role' THEN
    NEW.is_gps_verified := OLD.is_gps_verified;
    NEW.reporter_id := OLD.reporter_id;
    NEW.report_code := OLD.report_code;
  END IF;

  IF OLD.status IS DISTINCT FROM 'resolved' AND NEW.status = 'resolved' THEN
    NEW.resolved_at := COALESCE(NEW.resolved_at, now());
    IF NEW.resolved_by IS NULL AND auth.uid() IS NOT NULL THEN
      NEW.resolved_by := auth.uid();
    END IF;
  ELSIF NEW.status <> 'resolved' THEN
    NEW.resolved_at := NULL;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reports_before_update ON public.reports;
CREATE TRIGGER trg_reports_before_update
  BEFORE UPDATE ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.trg_reports_before_update_fn();

-- 7) Reports AFTER UPDATE OF status: award idempotent contribution points on resolution.
CREATE OR REPLACE FUNCTION public.trg_reports_award_points_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM 'resolved' AND NEW.status = 'resolved' THEN
    -- +20 points to the student who submitted the verified report
    IF NEW.reporter_id IS NOT NULL THEN
      INSERT INTO public.contribution_events (profile_id, report_id, points, reason, created_at)
      VALUES (
        NEW.reporter_id,
        NEW.id,
        20,
        'report_resolved_reporter',
        COALESCE(NEW.resolved_at, now())
      )
      ON CONFLICT (report_id, profile_id, reason) DO NOTHING;
    END IF;

    -- +10 points to the admin who resolved the report
    IF NEW.resolved_by IS NOT NULL AND NEW.resolved_by IS DISTINCT FROM NEW.reporter_id THEN
      INSERT INTO public.contribution_events (profile_id, report_id, points, reason, created_at)
      VALUES (
        NEW.resolved_by,
        NEW.id,
        10,
        'report_resolved_admin',
        COALESCE(NEW.resolved_at, now())
      )
      ON CONFLICT (report_id, profile_id, reason) DO NOTHING;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reports_award_points ON public.reports;
CREATE TRIGGER trg_reports_award_points
  AFTER UPDATE OF status ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.trg_reports_award_points_fn();

-- 8) Chat messages BEFORE INSERT: stamp sender alias & role from profiles server-side.
CREATE OR REPLACE FUNCTION public.trg_chat_messages_before_insert_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile RECORD;
BEGIN
  IF auth.role() <> 'service_role' THEN
    NEW.sender_id := auth.uid();
  END IF;

  IF NEW.sender_id IS NOT NULL THEN
    SELECT public_alias, role
      INTO v_profile
      FROM public.profiles
     WHERE id = NEW.sender_id;

    IF FOUND THEN
      NEW.sender_alias_snapshot := v_profile.public_alias;
      NEW.sender_role_snapshot := v_profile.role;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_chat_messages_before_insert ON public.chat_messages;
CREATE TRIGGER trg_chat_messages_before_insert
  BEFORE INSERT ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION public.trg_chat_messages_before_insert_fn();

-- 9) Enable Supabase Realtime on live tables
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.reports;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
  END IF;
END;
$$;
