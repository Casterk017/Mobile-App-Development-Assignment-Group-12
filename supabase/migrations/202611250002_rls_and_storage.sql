-- ============================================================================
-- Migration 0002: Row-Level Security (RLS) & Storage Bucket Policies
-- Campus Safety & Incident Reporting System (UTS Campus)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Helper Functions (SECURITY DEFINER to avoid RLS recursion on profiles)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.current_user_department()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT department FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.can_access_chat_channel(p_channel_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
      FROM public.chat_channels c
     WHERE c.id = p_channel_id
       AND (
         -- 1) Community group chat: all authenticated users & staff
         c.type = 'community'
         -- 2) Student <-> Department Admin chat:
         --    owning student, admins in that department, or super_admin oversight
         OR (
           c.type = 'user_admin'
           AND (
             c.student_id = auth.uid()
             OR (public.current_user_role() = 'admin' AND c.department = public.current_user_department())
             OR public.current_user_role() = 'super_admin'
           )
         )
         -- 3) Web Portal Admin <-> Super Admin direct chat: explicit members only
         OR (
           c.type = 'admin_super_admin'
           AND EXISTS (
             SELECT 1
               FROM public.chat_channel_members m
              WHERE m.channel_id = c.id
                AND m.profile_id = auth.uid()
           )
         )
       )
  );
$$;

-- ----------------------------------------------------------------------------
-- Enable RLS on all 12 tables
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campus_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.preset_pins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.category_department_map ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contribution_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_channel_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_message_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_blocked_users ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- 1. profiles
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS profiles_select_self ON public.profiles;
CREATE POLICY profiles_select_self ON public.profiles
  FOR SELECT TO authenticated
  USING (id = auth.uid());

DROP POLICY IF EXISTS profiles_select_admin ON public.profiles;
CREATE POLICY profiles_select_admin ON public.profiles
  FOR SELECT TO authenticated
  USING (
    public.current_user_role() = 'admin'
    AND (
      role IN ('admin', 'super_admin')
      OR EXISTS (
        SELECT 1
          FROM public.reports r
          JOIN public.category_department_map m ON m.category_key = r.category_key
         WHERE r.reporter_id = profiles.id
           AND m.department = public.current_user_department()
      )
      OR EXISTS (
        SELECT 1
          FROM public.chat_channels c
         WHERE c.type = 'user_admin'
           AND c.student_id = profiles.id
           AND c.department = public.current_user_department()
      )
    )
  );

DROP POLICY IF EXISTS profiles_select_super_admin ON public.profiles;
CREATE POLICY profiles_select_super_admin ON public.profiles
  FOR SELECT TO authenticated
  USING (public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS profiles_update_self ON public.profiles;
CREATE POLICY profiles_update_self ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS profiles_update_super_admin ON public.profiles;
CREATE POLICY profiles_update_super_admin ON public.profiles
  FOR UPDATE TO authenticated
  USING (public.current_user_role() = 'super_admin')
  WITH CHECK (public.current_user_role() = 'super_admin');

-- ----------------------------------------------------------------------------
-- 2. campus_settings
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS campus_settings_select_authenticated ON public.campus_settings;
CREATE POLICY campus_settings_select_authenticated ON public.campus_settings
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS campus_settings_update_super_admin ON public.campus_settings;
CREATE POLICY campus_settings_update_super_admin ON public.campus_settings
  FOR UPDATE TO authenticated
  USING (public.current_user_role() = 'super_admin')
  WITH CHECK (public.current_user_role() = 'super_admin');

-- ----------------------------------------------------------------------------
-- 3. preset_pins
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS preset_pins_select_authenticated ON public.preset_pins;
CREATE POLICY preset_pins_select_authenticated ON public.preset_pins
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS preset_pins_insert_super_admin ON public.preset_pins;
CREATE POLICY preset_pins_insert_super_admin ON public.preset_pins
  FOR INSERT TO authenticated
  WITH CHECK (public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS preset_pins_update_super_admin ON public.preset_pins;
CREATE POLICY preset_pins_update_super_admin ON public.preset_pins
  FOR UPDATE TO authenticated
  USING (public.current_user_role() = 'super_admin')
  WITH CHECK (public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS preset_pins_delete_super_admin ON public.preset_pins;
CREATE POLICY preset_pins_delete_super_admin ON public.preset_pins
  FOR DELETE TO authenticated
  USING (public.current_user_role() = 'super_admin');

-- ----------------------------------------------------------------------------
-- 4. category_department_map
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS category_map_select_active ON public.category_department_map;
CREATE POLICY category_map_select_active ON public.category_department_map
  FOR SELECT TO authenticated
  USING (is_active = true OR public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS category_map_insert_super_admin ON public.category_department_map;
CREATE POLICY category_map_insert_super_admin ON public.category_department_map
  FOR INSERT TO authenticated
  WITH CHECK (public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS category_map_update_super_admin ON public.category_department_map;
CREATE POLICY category_map_update_super_admin ON public.category_department_map
  FOR UPDATE TO authenticated
  USING (public.current_user_role() = 'super_admin')
  WITH CHECK (public.current_user_role() = 'super_admin');

-- ----------------------------------------------------------------------------
-- 5. reports
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS reports_select_own ON public.reports;
CREATE POLICY reports_select_own ON public.reports
  FOR SELECT TO authenticated
  USING (reporter_id = auth.uid());

DROP POLICY IF EXISTS reports_select_department_admin ON public.reports;
CREATE POLICY reports_select_department_admin ON public.reports
  FOR SELECT TO authenticated
  USING (
    public.current_user_role() = 'admin'
    AND EXISTS (
      SELECT 1
        FROM public.category_department_map m
       WHERE m.category_key = reports.category_key
         AND m.department = public.current_user_department()
    )
  );

DROP POLICY IF EXISTS reports_select_super_admin ON public.reports;
CREATE POLICY reports_select_super_admin ON public.reports
  FOR SELECT TO authenticated
  USING (public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS reports_insert_student ON public.reports;
CREATE POLICY reports_insert_student ON public.reports
  FOR INSERT TO authenticated
  WITH CHECK (
    reporter_id = auth.uid()
    AND EXISTS (
      SELECT 1
        FROM public.category_department_map m
       WHERE m.category_key = reports.category_key
         AND m.is_active = true
    )
  );

DROP POLICY IF EXISTS reports_update_department_admin ON public.reports;
CREATE POLICY reports_update_department_admin ON public.reports
  FOR UPDATE TO authenticated
  USING (
    public.current_user_role() = 'admin'
    AND EXISTS (
      SELECT 1
        FROM public.category_department_map m
       WHERE m.category_key = reports.category_key
         AND m.department = public.current_user_department()
    )
  )
  WITH CHECK (
    public.current_user_role() = 'admin'
    AND EXISTS (
      SELECT 1
        FROM public.category_department_map m
       WHERE m.category_key = reports.category_key
         AND m.department = public.current_user_department()
    )
  );

DROP POLICY IF EXISTS reports_update_super_admin ON public.reports;
CREATE POLICY reports_update_super_admin ON public.reports
  FOR UPDATE TO authenticated
  USING (public.current_user_role() = 'super_admin')
  WITH CHECK (public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS reports_delete_super_admin ON public.reports;
CREATE POLICY reports_delete_super_admin ON public.reports
  FOR DELETE TO authenticated
  USING (public.current_user_role() = 'super_admin');

-- ----------------------------------------------------------------------------
-- 6. report_updates
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS report_updates_select_visible ON public.report_updates;
CREATE POLICY report_updates_select_visible ON public.report_updates
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.reports r WHERE r.id = report_updates.report_id
    )
  );

DROP POLICY IF EXISTS report_updates_insert_staff ON public.report_updates;
CREATE POLICY report_updates_insert_staff ON public.report_updates
  FOR INSERT TO authenticated
  WITH CHECK (
    public.current_user_role() IN ('admin', 'super_admin')
    AND EXISTS (
      SELECT 1 FROM public.reports r WHERE r.id = report_updates.report_id
    )
  );

-- ----------------------------------------------------------------------------
-- 7. contribution_events
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS contribution_events_select_own ON public.contribution_events;
CREATE POLICY contribution_events_select_own ON public.contribution_events
  FOR SELECT TO authenticated
  USING (profile_id = auth.uid() OR public.current_user_role() = 'super_admin');

-- ----------------------------------------------------------------------------
-- 8. chat_channels & chat_channel_members
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS chat_channels_select_accessible ON public.chat_channels;
CREATE POLICY chat_channels_select_accessible ON public.chat_channels
  FOR SELECT TO authenticated
  USING (public.can_access_chat_channel(id));

DROP POLICY IF EXISTS chat_channel_members_select_own ON public.chat_channel_members;
CREATE POLICY chat_channel_members_select_own ON public.chat_channel_members
  FOR SELECT TO authenticated
  USING (
    profile_id = auth.uid()
    OR EXISTS (
      SELECT 1
        FROM public.chat_channel_members m2
       WHERE m2.channel_id = chat_channel_members.channel_id
         AND m2.profile_id = auth.uid()
    )
  );

-- ----------------------------------------------------------------------------
-- 9. chat_messages
--    Moderation split:
--    - admin: DELETE only inside 'community' channel
--    - super_admin: DELETE inside both 'community' and 'user_admin' channels
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS chat_messages_select_accessible ON public.chat_messages;
CREATE POLICY chat_messages_select_accessible ON public.chat_messages
  FOR SELECT TO authenticated
  USING (
    public.can_access_chat_channel(channel_id)
    AND (
      sender_id IS NULL
      OR NOT EXISTS (
        SELECT 1
          FROM public.chat_blocked_users b
         WHERE b.blocker_id = auth.uid()
           AND b.blocked_id = chat_messages.sender_id
      )
    )
  );

DROP POLICY IF EXISTS chat_messages_insert_accessible ON public.chat_messages;
CREATE POLICY chat_messages_insert_accessible ON public.chat_messages
  FOR INSERT TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND public.can_access_chat_channel(channel_id)
  );

DROP POLICY IF EXISTS chat_messages_delete_moderation ON public.chat_messages;
CREATE POLICY chat_messages_delete_moderation ON public.chat_messages
  FOR DELETE TO authenticated
  USING (
    (
      public.current_user_role() = 'admin'
      AND EXISTS (
        SELECT 1
          FROM public.chat_channels c
         WHERE c.id = chat_messages.channel_id
           AND c.type = 'community'
      )
    )
    OR (
      public.current_user_role() = 'super_admin'
      AND EXISTS (
        SELECT 1
          FROM public.chat_channels c
         WHERE c.id = chat_messages.channel_id
           AND c.type IN ('community', 'user_admin')
      )
    )
  );

-- ----------------------------------------------------------------------------
-- 10. chat_message_reports
--     Moderation split:
--     - admin: SELECT/UPDATE flags for 'community' messages ONLY
--     - super_admin: SELECT/UPDATE flags across 'community' & 'user_admin'
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS chat_message_reports_insert_authenticated ON public.chat_message_reports;
CREATE POLICY chat_message_reports_insert_authenticated ON public.chat_message_reports
  FOR INSERT TO authenticated
  WITH CHECK (
    reporter_id = auth.uid()
    AND EXISTS (
      SELECT 1
        FROM public.chat_messages msg
       WHERE msg.id = chat_message_reports.message_id
         AND public.can_access_chat_channel(msg.channel_id)
    )
  );

DROP POLICY IF EXISTS chat_message_reports_select_policy ON public.chat_message_reports;
CREATE POLICY chat_message_reports_select_policy ON public.chat_message_reports
  FOR SELECT TO authenticated
  USING (
    reporter_id = auth.uid()
    OR public.current_user_role() = 'super_admin'
    OR (
      public.current_user_role() = 'admin'
      AND EXISTS (
        SELECT 1
          FROM public.chat_messages msg
          JOIN public.chat_channels c ON c.id = msg.channel_id
         WHERE msg.id = chat_message_reports.message_id
           AND c.type = 'community'
      )
    )
  );

DROP POLICY IF EXISTS chat_message_reports_update_moderation ON public.chat_message_reports;
CREATE POLICY chat_message_reports_update_moderation ON public.chat_message_reports
  FOR UPDATE TO authenticated
  USING (
    public.current_user_role() = 'super_admin'
    OR (
      public.current_user_role() = 'admin'
      AND EXISTS (
        SELECT 1
          FROM public.chat_messages msg
          JOIN public.chat_channels c ON c.id = msg.channel_id
         WHERE msg.id = chat_message_reports.message_id
           AND c.type = 'community'
      )
    )
  )
  WITH CHECK (
    public.current_user_role() = 'super_admin'
    OR (
      public.current_user_role() = 'admin'
      AND EXISTS (
        SELECT 1
          FROM public.chat_messages msg
          JOIN public.chat_channels c ON c.id = msg.channel_id
         WHERE msg.id = chat_message_reports.message_id
           AND c.type = 'community'
      )
    )
  );

-- ----------------------------------------------------------------------------
-- 11. chat_blocked_users
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS chat_blocked_users_own ON public.chat_blocked_users;
CREATE POLICY chat_blocked_users_own ON public.chat_blocked_users
  FOR ALL TO authenticated
  USING (blocker_id = auth.uid())
  WITH CHECK (blocker_id = auth.uid());

-- ============================================================================
-- Storage Buckets & Object Policies
-- ============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('report-attachments', 'report-attachments', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('pin-images', 'pin-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- Private bucket: report-attachments
-- Path convention: {reporter_uid}/{report_id_or_upload_batch}/{filename}
DROP POLICY IF EXISTS report_attachments_insert_own ON storage.objects;
CREATE POLICY report_attachments_insert_own ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'report-attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS report_attachments_select_rbac ON storage.objects;
CREATE POLICY report_attachments_select_rbac ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'report-attachments'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.current_user_role() = 'super_admin'
      OR (
        public.current_user_role() = 'admin'
        AND EXISTS (
          SELECT 1
            FROM public.reports r
            JOIN public.category_department_map m ON m.category_key = r.category_key
           WHERE m.department = public.current_user_department()
             AND name = ANY(r.attachment_paths)
        )
      )
    )
  );

DROP POLICY IF EXISTS report_attachments_delete_super_admin ON storage.objects;
CREATE POLICY report_attachments_delete_super_admin ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'report-attachments'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.current_user_role() = 'super_admin'
    )
  );

-- Public bucket: pin-images
DROP POLICY IF EXISTS pin_images_public_read ON storage.objects;
CREATE POLICY pin_images_public_read ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'pin-images');

DROP POLICY IF EXISTS pin_images_super_admin_write ON storage.objects;
CREATE POLICY pin_images_super_admin_write ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'pin-images'
    AND public.current_user_role() = 'super_admin'
  );

DROP POLICY IF EXISTS pin_images_super_admin_update ON storage.objects;
CREATE POLICY pin_images_super_admin_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'pin-images'
    AND public.current_user_role() = 'super_admin'
  );

DROP POLICY IF EXISTS pin_images_super_admin_delete ON storage.objects;
CREATE POLICY pin_images_super_admin_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'pin-images'
    AND public.current_user_role() = 'super_admin'
  );
