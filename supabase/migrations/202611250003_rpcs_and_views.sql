-- ============================================================================
-- Migration 0003: RPC Functions (Map Summaries, Leaderboard, Stats, Chat, Reports)
-- Campus Safety & Incident Reporting System (UTS Campus)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Privacy-Safe Map Pin Report Summaries (no reporter PII or descriptions)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_pin_report_summaries(
  p_pin_id TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  pin_id TEXT,
  title TEXT,
  reported_at TIMESTAMPTZ,
  is_solved BOOLEAN,
  resolved_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    r.id,
    r.pin_id,
    r.title,
    r.submitted_at AS reported_at,
    (r.status = 'resolved') AS is_solved,
    r.resolved_at
  FROM public.reports r
  WHERE r.pin_id IS NOT NULL
    AND r.status <> 'rejected'
    AND (p_pin_id IS NULL OR r.pin_id = p_pin_id)
  ORDER BY r.submitted_at DESC;
$$;

-- ----------------------------------------------------------------------------
-- 2. Leaderboard (Top 20 default) for Students ('user') or Admins ('admin')
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_leaderboard(
  p_role TEXT DEFAULT 'user',
  p_period TEXT DEFAULT 'monthly',
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  profile_id UUID,
  rank BIGINT,
  public_alias TEXT,
  department TEXT,
  points BIGINT,
  verified_contributions BIGINT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role TEXT;
  v_period_start TIMESTAMPTZ := NULL;
  v_safe_limit INTEGER := GREATEST(1, LEAST(COALESCE(p_limit, 20), 100));
BEGIN
  SELECT role INTO v_caller_role FROM public.profiles WHERE id = auth.uid();

  IF p_role NOT IN ('user', 'admin') THEN
    RAISE EXCEPTION 'Invalid leaderboard role: %', p_role;
  END IF;

  IF p_role = 'admin' AND COALESCE(v_caller_role, 'user') <> 'super_admin' THEN
    RAISE EXCEPTION 'Only Super Admin can view admin rankings.';
  END IF;

  IF p_period NOT IN ('monthly', 'all_time') THEN
    RAISE EXCEPTION 'Invalid leaderboard period: %', p_period;
  END IF;

  IF p_period = 'monthly' THEN
    v_period_start := date_trunc('month', now());
  END IF;

  RETURN QUERY
  WITH scored AS (
    SELECT
      p.id AS profile_id,
      p.public_alias,
      p.department,
      SUM(ce.points)::BIGINT AS points,
      COUNT(ce.id)::BIGINT AS verified_contributions
    FROM public.contribution_events ce
    JOIN public.profiles p ON p.id = ce.profile_id
    WHERE p.role = p_role
      AND (v_period_start IS NULL OR ce.created_at >= v_period_start)
    GROUP BY p.id, p.public_alias, p.department
  )
  SELECT
    s.profile_id,
    DENSE_RANK() OVER (ORDER BY s.points DESC, s.verified_contributions DESC, s.public_alias ASC) AS rank,
    s.public_alias,
    s.department,
    s.points,
    s.verified_contributions
  FROM scored s
  ORDER BY rank ASC, s.public_alias ASC
  LIMIT v_safe_limit;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. Logged-in User's Own Rank (even when outside Top 20)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_my_rank(
  p_period TEXT DEFAULT 'monthly'
)
RETURNS TABLE (
  profile_id UUID,
  rank BIGINT,
  public_alias TEXT,
  department TEXT,
  points BIGINT,
  verified_contributions BIGINT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_my_role TEXT;
  v_period_start TIMESTAMPTZ := NULL;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_period NOT IN ('monthly', 'all_time') THEN
    RAISE EXCEPTION 'Invalid leaderboard period: %', p_period;
  END IF;

  IF p_period = 'monthly' THEN
    v_period_start := date_trunc('month', now());
  END IF;

  SELECT role INTO v_my_role FROM public.profiles WHERE id = auth.uid();

  RETURN QUERY
  WITH scored AS (
    SELECT
      p.id AS profile_id,
      p.public_alias,
      p.department,
      SUM(ce.points)::BIGINT AS points,
      COUNT(ce.id)::BIGINT AS verified_contributions
    FROM public.contribution_events ce
    JOIN public.profiles p ON p.id = ce.profile_id
    WHERE p.role = COALESCE(v_my_role, 'user')
      AND (v_period_start IS NULL OR ce.created_at >= v_period_start)
    GROUP BY p.id, p.public_alias, p.department
  ),
  ranked AS (
    SELECT
      s.profile_id,
      DENSE_RANK() OVER (ORDER BY s.points DESC, s.verified_contributions DESC, s.public_alias ASC) AS rank,
      s.public_alias,
      s.department,
      s.points,
      s.verified_contributions
    FROM scored s
  )
  SELECT
    r.profile_id,
    r.rank,
    r.public_alias,
    r.department,
    r.points,
    r.verified_contributions
  FROM ranked r
  WHERE r.profile_id = auth.uid();
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. Admin & Super Admin Dashboard Stats (RLS-scoped automatically via INVOKER)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS TABLE (
  waiting_count BIGINT,
  pending_count BIGINT,
  in_progress_count BIGINT,
  resolved_count BIGINT,
  rejected_count BIGINT,
  total_count BIGINT
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    COUNT(*) FILTER (WHERE status IN ('pending', 'in_progress'))::BIGINT AS waiting_count,
    COUNT(*) FILTER (WHERE status = 'pending')::BIGINT AS pending_count,
    COUNT(*) FILTER (WHERE status = 'in_progress')::BIGINT AS in_progress_count,
    COUNT(*) FILTER (WHERE status = 'resolved')::BIGINT AS resolved_count,
    COUNT(*) FILTER (WHERE status = 'rejected')::BIGINT AS rejected_count,
    COUNT(*)::BIGINT AS total_count
  FROM public.reports;
$$;

-- ----------------------------------------------------------------------------
-- 5. Mobile Chat: Get or Create Student <-> Department Channel
--    Strictly limited to the 4 fixed departments (excludes super_admin).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_or_create_department_chat(
  p_department TEXT
)
RETURNS public.chat_channels
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller RECORD;
  v_channel public.chat_channels;
  v_label TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  SELECT id, role, public_alias INTO v_caller FROM public.profiles WHERE id = auth.uid();
  IF NOT FOUND OR v_caller.role <> 'user' THEN
    RAISE EXCEPTION 'Only students can open a department support chat.';
  END IF;

  IF p_department NOT IN ('facilities', 'cleaner', 'parking', 'security') THEN
    RAISE EXCEPTION 'Invalid department: %. Must be facilities, cleaner, parking, or security.', p_department;
  END IF;

  SELECT *
    INTO v_channel
    FROM public.chat_channels
   WHERE type = 'user_admin'
     AND student_id = auth.uid()
     AND department = p_department;

  IF FOUND THEN
    RETURN v_channel;
  END IF;

  v_label := CASE p_department
    WHEN 'facilities' THEN 'Facilities Support'
    WHEN 'cleaner' THEN 'Cleaner Support'
    WHEN 'parking' THEN 'Parking Support'
    WHEN 'security' THEN 'Security Support'
  END;

  INSERT INTO public.chat_channels (type, name, department, student_id)
  VALUES ('user_admin', v_label || ' · ' || v_caller.public_alias, p_department, auth.uid())
  ON CONFLICT (student_id, department) WHERE (type = 'user_admin' AND student_id IS NOT NULL)
  DO UPDATE SET name = EXCLUDED.name
  RETURNING * INTO v_channel;

  RETURN v_channel;
END;
$$;

-- ----------------------------------------------------------------------------
-- 6. Web Portal Chat: Get or Create Admin <-> Super Admin Direct Channel
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_or_create_admin_super_admin_channel(
  p_target_profile_id UUID
)
RETURNS public.chat_channels
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller RECORD;
  v_target RECORD;
  v_channel public.chat_channels;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF p_target_profile_id = auth.uid() THEN
    RAISE EXCEPTION 'Cannot create a direct chat channel with yourself.';
  END IF;

  SELECT id, role, display_name INTO v_caller FROM public.profiles WHERE id = auth.uid();
  SELECT id, role, display_name INTO v_target FROM public.profiles WHERE id = p_target_profile_id;

  IF v_caller.id IS NULL OR v_target.id IS NULL THEN
    RAISE EXCEPTION 'Profile not found.';
  END IF;

  IF NOT (
    (v_caller.role = 'admin' AND v_target.role = 'super_admin')
    OR (v_caller.role = 'super_admin' AND v_target.role = 'admin')
  ) THEN
    RAISE EXCEPTION 'Staff direct chat requires one admin and one super_admin.';
  END IF;

  SELECT c.*
    INTO v_channel
    FROM public.chat_channels c
    JOIN public.chat_channel_members m1 ON m1.channel_id = c.id AND m1.profile_id = auth.uid()
    JOIN public.chat_channel_members m2 ON m2.channel_id = c.id AND m2.profile_id = p_target_profile_id
   WHERE c.type = 'admin_super_admin'
   LIMIT 1;

  IF FOUND THEN
    RETURN v_channel;
  END IF;

  INSERT INTO public.chat_channels (type, name)
  VALUES ('admin_super_admin', v_caller.display_name || ' ↔ ' || v_target.display_name)
  RETURNING * INTO v_channel;

  INSERT INTO public.chat_channel_members (channel_id, profile_id)
  VALUES
    (v_channel.id, auth.uid()),
    (v_channel.id, p_target_profile_id)
  ON CONFLICT DO NOTHING;

  RETURN v_channel;
END;
$$;

-- ----------------------------------------------------------------------------
-- 7. Atomic Report Status Update + Timeline Append (RLS-enforced via INVOKER)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_report_status(
  p_report_id UUID,
  p_new_status TEXT,
  p_note TEXT
)
RETURNS public.reports
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_updated public.reports;
BEGIN
  IF p_new_status NOT IN ('pending', 'in_progress', 'resolved', 'rejected') THEN
    RAISE EXCEPTION 'Invalid report status: %', p_new_status;
  END IF;

  IF p_note IS NULL OR char_length(trim(p_note)) = 0 THEN
    RAISE EXCEPTION 'A status update note is required.';
  END IF;

  UPDATE public.reports
     SET status = p_new_status,
         resolved_by = CASE WHEN p_new_status = 'resolved' THEN auth.uid() ELSE resolved_by END
   WHERE id = p_report_id
  RETURNING * INTO v_updated;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Report not found or you do not have permission to update it.';
  END IF;

  INSERT INTO public.report_updates (report_id, actor_id, status, note)
  VALUES (p_report_id, auth.uid(), p_new_status, trim(p_note));

  RETURN v_updated;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_pin_report_summaries(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_leaderboard(TEXT, TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_rank(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_dashboard_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_department_chat(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_admin_super_admin_channel(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_report_status(UUID, TEXT, TEXT) TO authenticated;
