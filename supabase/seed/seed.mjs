/**
 * Idempotent Seed Script for Campus Safety & Incident Reporting System (UTS)
 *
 * Usage:
 *   1. Copy supabase/.env.example -> supabase/.env and fill SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY
 *   2. Run migrations 0001..0004 in Supabase first
 *   3. Execute: node --env-file=supabase/.env supabase/seed/seed.mjs
 */

import { createClient } from '../../Website/node_modules/@supabase/supabase-js/dist/index.mjs';

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const DEFAULT_PASSWORD = process.env.SEED_DEFAULT_PASSWORD || 'CampusSafe123!';
const COMMUNITY_CHANNEL_ID = '00000000-0000-0000-0000-000000000001';

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in environment.');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const SEED_ACCOUNTS = [
  // 1 Super Admin
  {
    key: 'super_admin',
    email: 'superadmin@uts.edu.my',
    displayName: 'Dr. Lim Wei Ming',
    publicAlias: 'Campus Super Admin',
    role: 'super_admin',
    department: null,
  },
  // 4 Department Admins (one per fixed department)
  {
    key: 'admin_facilities',
    email: 'facilities.admin@uts.edu.my',
    displayName: 'Encik Hafiz Rahman',
    publicAlias: 'Facilities Admin',
    role: 'admin',
    department: 'facilities',
  },
  {
    key: 'admin_cleaner',
    email: 'cleaner.admin@uts.edu.my',
    displayName: 'Puan Siti Nurhaliza',
    publicAlias: 'Cleaner Admin',
    role: 'admin',
    department: 'cleaner',
  },
  {
    key: 'admin_parking',
    email: 'parking.admin@uts.edu.my',
    displayName: 'Mr. Kelvin Tan',
    publicAlias: 'Parking Admin',
    role: 'admin',
    department: 'parking',
  },
  {
    key: 'admin_security',
    email: 'security.admin@uts.edu.my',
    displayName: 'Officer Daniel Wong',
    publicAlias: 'Security Admin',
    role: 'admin',
    department: 'security',
  },
  // 6 Students (matching UserDashboard's privacy-safe aliases)
  {
    key: 'student_fern',
    email: 'fern@student.uts.edu.my',
    displayName: 'Aina Sofea',
    publicAlias: 'Campus Fern',
    role: 'user',
    department: null,
  },
  {
    key: 'student_river',
    email: 'river@student.uts.edu.my',
    displayName: 'Bryan Ling',
    publicAlias: 'River Guide',
    role: 'user',
    department: null,
  },
  {
    key: 'student_cedar',
    email: 'cedar@student.uts.edu.my',
    displayName: 'Chong Jia Wei',
    publicAlias: 'Kind Cedar',
    role: 'user',
    department: null,
  },
  {
    key: 'student_oak',
    email: 'oak@student.uts.edu.my',
    displayName: 'Edmund Chai En Yun',
    publicAlias: 'Quiet Oak',
    role: 'user',
    department: null,
  },
  {
    key: 'student_iris',
    email: 'iris@student.uts.edu.my',
    displayName: 'Nurul Izzah',
    publicAlias: 'Blue Iris',
    role: 'user',
    department: null,
  },
  {
    key: 'student_pine',
    email: 'pine@student.uts.edu.my',
    displayName: 'Marcus Lau',
    publicAlias: 'Steady Pine',
    role: 'user',
    department: null,
  },
];

async function ensureUser(account) {
  const { data: existingProfile } = await supabase
    .from('profiles')
    .select('id, email')
    .eq('email', account.email)
    .maybeSingle();

  if (existingProfile?.id) {
    return existingProfile.id;
  }

  const { data, error } = await supabase.auth.admin.createUser({
    email: account.email,
    password: DEFAULT_PASSWORD,
    email_confirm: true,
    app_metadata: {
      role: account.role,
      ...(account.department ? { department: account.department } : {}),
    },
    user_metadata: {
      display_name: account.displayName,
      public_alias: account.publicAlias,
    },
  });

  if (error) {
    throw new Error(`Failed creating ${account.email}: ${error.message}`);
  }
  return data.user.id;
}

async function seedReports(ids) {
  const sampleReports = [
    {
      report_code: 'UTS-1001',
      reporter_id: ids.student_oak,
      pin_id: 'pin_academic_resources',
      category_key: 'lighting',
      title: 'Dim walkway lights near Academic Resource Centre',
      location: 'Academic Resource Centre · East path',
      description: 'Two walkway LED lamps flicker after sunset, reducing visibility near the steps.',
      reporter_lat: 2.341361,
      reporter_lng: 111.846111,
      targetStatus: 'pending',
      resolverKey: null,
      note: null,
    },
    {
      report_code: 'UTS-1002',
      reporter_id: ids.student_oak,
      pin_id: 'pin_block_5',
      category_key: 'facilities',
      title: 'Loose staircase handrail at Block 5',
      location: 'UTS Block 5 · South stairs',
      description: 'Lower bracket of the metal handrail is loose when descending to ground floor.',
      reporter_lat: 2.340639,
      reporter_lng: 111.844194,
      targetStatus: 'in_progress',
      resolverKey: 'admin_facilities',
      note: 'Facilities maintenance technician scheduled to tighten anchor bolts.',
    },
    {
      report_code: 'UTS-1003',
      reporter_id: ids.student_oak,
      pin_id: 'pin_student_dev',
      category_key: 'access',
      title: 'Obstructed accessible ramp at Student Dev Centre',
      location: 'Student Development & Services Centre · Entrance B',
      description: 'Stacked event tables were partially blocking the wheelchair ramp.',
      reporter_lat: 2.341056,
      reporter_lng: 111.845917,
      targetStatus: 'resolved',
      resolverKey: 'admin_facilities',
      note: 'Tables relocated to storage; ramp is now completely clear.',
    },
    {
      report_code: 'UTS-1004',
      reporter_id: ids.student_fern,
      pin_id: 'pin_street_cafe',
      category_key: 'environment',
      title: 'Overflowing recycling bins behind Street Cafe',
      location: 'UTS Street Cafe · North corner',
      description: 'Recycling bins are full and attracting pests near the seating walkway.',
      reporter_lat: 2.340833,
      reporter_lng: 111.846056,
      targetStatus: 'resolved',
      resolverKey: 'admin_cleaner',
      note: 'Bins emptied, sanitized, and extra liner added.',
    },
    {
      report_code: 'UTS-1005',
      reporter_id: ids.student_river,
      pin_id: 'pin_carpark',
      category_key: 'parking',
      title: 'Vehicle blocking emergency fire lane',
      location: 'Multi-Storey Carpark · Level 1 Ramp',
      description: 'A white sedan is parked across the yellow hatched fire-access zone.',
      reporter_lat: 2.342083,
      reporter_lng: 111.846417,
      targetStatus: 'resolved',
      resolverKey: 'admin_parking',
      note: 'Owner contacted via campus registry and vehicle moved promptly.',
    },
    {
      report_code: 'UTS-1006',
      reporter_id: ids.student_cedar,
      pin_id: 'pin_main_entrance',
      category_key: 'security',
      title: 'Side pedestrian gate latch not locking',
      location: 'UTS Main Entrance · Pedestrian side gate',
      description: 'The magnetic latch does not engage after students swipe through at night.',
      reporter_lat: 2.34125,
      reporter_lng: 111.842444,
      targetStatus: 'resolved',
      resolverKey: 'admin_security',
      note: 'Security patrol verified and magnetic lock recalibrated.',
    },
    {
      report_code: 'UTS-1007',
      reporter_id: ids.student_iris,
      pin_id: 'pin_recreation',
      category_key: 'environment',
      title: 'Slippery water puddle near indoor courts',
      location: 'Recreation Center · Court 2 entrance',
      description: 'Condensation from the water cooler created a slippery patch on the tile floor.',
      reporter_lat: 2.340806,
      reporter_lng: 111.849889,
      targetStatus: 'resolved',
      resolverKey: 'admin_cleaner',
      note: 'Area mopped dry and wet-floor signage placed.',
    },
    {
      report_code: 'UTS-1008',
      reporter_id: ids.student_pine,
      pin_id: 'pin_hostel',
      category_key: 'lighting',
      title: 'Duplicate report for hostel corridor bulb',
      location: 'UTS Hostel · Block B Level 2',
      description: 'Corridor light flickering (duplicate of an existing open ticket).',
      reporter_lat: 2.341444,
      reporter_lng: 111.849111,
      targetStatus: 'rejected',
      resolverKey: 'admin_facilities',
      note: 'Duplicate of an existing maintenance case already in progress.',
    },
  ];

  for (const r of sampleReports) {
    const { data: existing } = await supabase
      .from('reports')
      .select('id')
      .eq('report_code', r.report_code)
      .maybeSingle();

    if (existing?.id) continue;

    const { data: inserted, error: insertError } = await supabase
      .from('reports')
      .insert({
        report_code: r.report_code,
        reporter_id: r.reporter_id,
        pin_id: r.pin_id,
        category_key: r.category_key,
        title: r.title,
        location: r.location,
        description: r.description,
        status: 'pending',
        reporter_lat: r.reporter_lat,
        reporter_lng: r.reporter_lng,
      })
      .select('id')
      .single();

    if (insertError) {
      throw new Error(`Failed inserting ${r.report_code}: ${insertError.message}`);
    }

    if (r.targetStatus !== 'pending') {
      const resolverId = r.resolverKey ? ids[r.resolverKey] : null;
      const { error: updateError } = await supabase
        .from('reports')
        .update({
          status: r.targetStatus,
          resolved_by: r.targetStatus === 'resolved' ? resolverId : null,
        })
        .eq('id', inserted.id);

      if (updateError) {
        throw new Error(`Failed updating ${r.report_code}: ${updateError.message}`);
      }

      if (r.note) {
        await supabase.from('report_updates').insert({
          report_id: inserted.id,
          actor_id: resolverId,
          status: r.targetStatus,
          note: r.note,
        });
      }
    }
  }
}

async function seedChat(ids) {
  // 1. Seed community chat messages if empty
  const { count: communityCount } = await supabase
    .from('chat_messages')
    .select('id', { count: 'exact', head: true })
    .eq('channel_id', COMMUNITY_CHANNEL_ID);

  if (!communityCount) {
    await supabase.from('chat_messages').insert([
      {
        channel_id: COMMUNITY_CHANNEL_ID,
        sender_id: ids.student_fern,
        body: 'Friendly reminder to keep accessible entrances clear around Student Dev Centre!',
      },
      {
        channel_id: COMMUNITY_CHANNEL_ID,
        sender_id: ids.admin_facilities,
        body: 'Thank you everyone! Please submit maintenance issues via the Campus Map report form so our team can track them.',
      },
      {
        channel_id: COMMUNITY_CHANNEL_ID,
        sender_id: ids.student_oak,
        body: 'Appreciate the quick response on the ramp clearing today!',
      },
    ]);
  }

  // 2. Seed one student <-> department support channel (Quiet Oak <-> Facilities)
  const { data: existingDeptChan } = await supabase
    .from('chat_channels')
    .select('id')
    .eq('type', 'user_admin')
    .eq('student_id', ids.student_oak)
    .eq('department', 'facilities')
    .maybeSingle();

  let deptChannelId = existingDeptChan?.id;
  if (!deptChannelId) {
    const { data: created } = await supabase
      .from('chat_channels')
      .insert({
        type: 'user_admin',
        name: 'Facilities Support · Quiet Oak',
        department: 'facilities',
        student_id: ids.student_oak,
      })
      .select('id')
      .single();
    deptChannelId = created?.id;

    if (deptChannelId) {
      await supabase.from('chat_messages').insert([
        {
          channel_id: deptChannelId,
          sender_id: ids.student_oak,
          body: 'Hi Facilities team, is the Block 5 south staircase safe to use while the handrail is being fixed?',
        },
        {
          channel_id: deptChannelId,
          sender_id: ids.admin_facilities,
          body: 'Hi! Yes, we placed a caution sign on the lower rail and our technician will tighten it this afternoon.',
        },
      ]);
    }
  }

  // 3. Seed one Web Portal admin <-> super_admin channel
  const { data: existingStaff } = await supabase
    .from('chat_channels')
    .select('id')
    .eq('type', 'admin_super_admin')
    .limit(1)
    .maybeSingle();

  if (!existingStaff?.id) {
    const { data: staffChan } = await supabase
      .from('chat_channels')
      .insert({
        type: 'admin_super_admin',
        name: 'Facilities Admin ↔ Super Admin',
      })
      .select('id')
      .single();

    if (staffChan?.id) {
      await supabase.from('chat_channel_members').insert([
        { channel_id: staffChan.id, profile_id: ids.admin_facilities },
        { channel_id: staffChan.id, profile_id: ids.super_admin },
      ]);

      await supabase.from('chat_messages').insert([
        {
          channel_id: staffChan.id,
          sender_id: ids.super_admin,
          body: 'Welcome to the Campus Safety Portal. Please review pending facilities tickets before 5 PM.',
        },
        {
          channel_id: staffChan.id,
          sender_id: ids.admin_facilities,
          body: 'Noted! Block 5 handrail is already in progress.',
        },
      ]);
    }
  }
}

async function main() {
  console.log('Seeding Campus Safety & Incident Reporting System...');
  const ids = {};
  for (const account of SEED_ACCOUNTS) {
    ids[account.key] = await ensureUser(account);
    console.log(`  [OK] ${account.role.padEnd(11)} ${account.email}`);
  }

  await seedReports(ids);
  console.log('  [OK] Sample reports, timelines, and contribution points seeded.');

  await seedChat(ids);
  console.log('  [OK] Sample community, department support, and staff chat seeded.');

  console.log(`\nDone! Default password for all seeded accounts: ${DEFAULT_PASSWORD}`);
}

main().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
