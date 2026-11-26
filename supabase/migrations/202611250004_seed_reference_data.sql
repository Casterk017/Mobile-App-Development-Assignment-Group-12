-- ============================================================================
-- Migration 0004: Static Reference Data (UTS Bounds, 19 Pins, Categories, Chat)
-- Campus Safety & Incident Reporting System (UTS Campus)
-- ============================================================================

-- 1. Default UTS Campus GPS Bounds (expandable by Super Admin)
INSERT INTO public.campus_settings (id, min_lat, max_lat, min_lng, max_lng)
VALUES ('default', 2.340000, 2.342800, 111.841500, 111.850500)
ON CONFLICT (id) DO NOTHING;

-- 2. Initial Report Categories -> Fixed 4 Admin Departments
INSERT INTO public.category_department_map (category_key, display_label, department, is_active)
VALUES
  ('lighting', 'Lighting Issue', 'facilities', true),
  ('facilities', 'Broken Facility / Equipment', 'facilities', true),
  ('access', 'Door / Gate Access Issue', 'facilities', true),
  ('environment', 'Cleanliness & Environment', 'cleaner', true),
  ('parking', 'Parking Violation / Issue', 'parking', true),
  ('security', 'Security & Safety Threat', 'security', true)
ON CONFLICT (category_key) DO NOTHING;

-- 3. All 19 UTS Campus Preset Pins (from Android/lib/Map/features/campus_map/data/map_remote_datasource.dart)
INSERT INTO public.preset_pins (id, block_name, section_title, description, lat, lng, image_urls)
VALUES
  ('pin_main_entrance', 'UTS Main Entrance', 'Entrance', 'Main guardhouse and entrance to the campus.', 2.341250, 111.842444, '{}'),
  ('pin_surau', 'Surau Pusat Islam UTS', 'Religious Facility', 'Islamic prayer center for students and staff.', 2.341944, 111.842333, '{}'),
  ('pin_chancellor_hall', 'Tun Abdul Taib Mahmud Chancellor Hall', 'Main Hall', 'Grand hall for convocations and major events.', 2.342306, 111.843222, '{}'),
  ('pin_admin', 'Administration Block', 'Office', 'UTS administrative and management offices.', 2.341306, 111.844500, '{}'),
  ('pin_block_1', 'UTS Block 1', 'Academic Block', 'Classrooms and faculty offices.', 2.341667, 111.844333, '{}'),
  ('pin_block_2', 'UTS Block 2', 'Academic Block', 'Classrooms and student facilities.', 2.341500, 111.844806, '{}'),
  ('pin_block_4', 'UTS Block 4', 'Academic Block', 'Classrooms and lecture halls.', 2.340917, 111.844667, '{}'),
  ('pin_block_5', 'UTS Block 5', 'Academic Block', 'Laboratories and specialized learning areas.', 2.340639, 111.844194, '{}'),
  ('pin_block_6', 'UTS Block 6', 'Academic Block', 'Engineering and technology workshops.', 2.340667, 111.845750, '{}'),
  ('pin_block_7', 'UTS Block 7', 'Academic Block', 'Design and computing facilities.', 2.340861, 111.845389, '{}'),
  ('pin_block_8', 'UTS Block 8', 'Academic Block', 'General study areas and faculty rooms.', 2.341417, 111.845167, '{}'),
  ('pin_block_9', 'UTS Block 9', 'Academic Block', 'Lecture rooms and tutorial spaces.', 2.341639, 111.845333, '{}'),
  ('pin_academic_resources', 'Academic Resource Centre', 'Library', 'Main university library and study resources.', 2.341361, 111.846111, '{}'),
  ('pin_street_cafe', 'UTS Street Cafe', 'Dining', 'Campus cafe offering various meals and drinks.', 2.340833, 111.846056, '{}'),
  ('pin_student_dev', 'Student Development & Services Centre', 'Services', 'Support center for student welfare and activities.', 2.341056, 111.845917, '{}'),
  ('pin_block_11', 'UTS Block 11', 'Academic Block', 'Advanced laboratories and research centers.', 2.341528, 111.846694, '{}'),
  ('pin_carpark', 'Multi-Storey Carpark', 'Facility', 'Covered parking area for students and staff.', 2.342083, 111.846417, '{}'),
  ('pin_hostel', 'UTS Hostel', 'Accommodation', 'On-campus student accommodation and living quarters.', 2.341444, 111.849111, '{}'),
  ('pin_recreation', 'Recreation Center', 'Sports Complex', 'Main indoor sports complex and gymnasium.', 2.340806, 111.849889, '{}')
ON CONFLICT (id) DO NOTHING;

-- 4. Default Campus Community Chat Channel (deterministic UUID)
INSERT INTO public.chat_channels (id, type, name)
VALUES ('00000000-0000-0000-0000-000000000001', 'community', 'Campus Safety Circle')
ON CONFLICT (id) DO NOTHING;
