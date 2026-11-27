# UTS Campus Safety & Incident Reporting System

**Repository:** `Mobile-App-Development-Assignment-Group-12`

---

## 1. What This Project Is About

The **UTS Campus Safety & Incident Reporting System** is a cross-platform mobile and web application built for the **University of Technology Sarawak (UTS)** campus community for a Mobile App Development course assignment. Students report on-campus safety, maintenance, cleanliness, and parking issues via a **Flutter (Android)** mobile app, while department staff and a Super Admin triage, resolve, and oversee campus operations through a **TypeScript + Vite** web admin portal backed by **Supabase** (PostgreSQL, Auth, Row-Level Security, Storage, Realtime, and Edge Functions).

- **Architecture Strategy:** The repository uses a **decoupled monorepo** split into two independent client folders (`Android/` and `Website/`) plus a shared backend folder (`supabase/`). Every team member works inside an isolated feature folder and interacts with Supabase strictly through standardized wrapper functions (`Database/`), preventing merge conflicts and keeping UI code completely separated from raw database queries.

### Tech Stack

- **Mobile Application (`Android/`):** Flutter (Dart) with `supabase_flutter` & `flutter_dotenv`
- **Web Administration Portal (`Website/`):** TypeScript + Vite (`@supabase/supabase-js`)
- **Backend, Auth & Security (`supabase/` + `Database/`):** Supabase (PostgreSQL, Auth, Row-Level Security, Storage, Realtime, Edge Functions), environment-variable secret management (`.env`), and pre-seeded dummy data for testing.

### System Roles & Access Model

- **Student (`user`):** Self-registers on mobile; submits incident reports anchored to campus map pins, tracks report timelines, participates in community and department chats, and earns contribution points.
- **Department Admin (`admin`):** Provisioned by the Super Admin into one of four fixed departments — **`facilities`**, **`cleaner`**, **`parking`**, or **`security`** — with scoped access to department reports, student support chats, and community moderation.
- **Super Admin (`super_admin`):** Full system oversight across all departments, accounts, dynamic report categories, interactive map pins, campus GPS boundaries, chat moderation, and both student and admin leaderboards.

### Team Roles & Ownership

- `Casterk017` — Project Architecture, Supabase Backend, RLS Security Rules & Cross-Platform `Database/` Wrappers
- `JoeyHi` — Web Admin & Super Admin Dashboard UI
- `Kaisheng1030` — Mobile User Dashboard UI & Analytics
- `HamsterSaMe` — Mobile Interactive Map, Preset Pins & GPS Location Verification
- `wongenxi` — Cross-Platform Incident Reporting (Mobile Submission & Web Display)

---

## 2. What Each Folder Is For

```text
Mobile-App-Development-Assignment-Group-12/
├── .github/
│   └── CODEOWNERS
├── supabase/
│   ├── migrations/
│   │   ├── 202611250001_core_schema.sql
│   │   ├── 202611250002_rls_and_storage.sql
│   │   ├── 202611250003_rpcs_and_views.sql
│   │   └── 202611250004_seed_reference_data.sql
│   ├── functions/
│   │   └── admin-accounts/index.ts
│   ├── seed/
│   │   └── seed.mjs
│   ├── .env.example
│   ├── .gitignore
│   └── README.md
├── Android/
│   ├── android/
│   ├── ios/
│   ├── lib/
│   │   ├── Database/
│   │   ├── Map/
│   │   ├── Report/
│   │   └── UserDashboard/
│   ├── test/
│   ├── web/
│   ├── .env.example
│   ├── .gitignore
│   └── pubspec.yaml
├── Website/
│   ├── src/
│   │   ├── AdminDashboard/
│   │   ├── Database/
│   │   └── Report/
│   ├── .env.example
│   ├── .gitignore
│   ├── package.json
│   └── tsconfig.json
├── .gitignore
└── Readme.md
```

### Root & Backend Folders

- `.github/CODEOWNERS`: Enforces folder-level Pull Request review rules so teammates only modify their own modules.
- `supabase/` (Owner: `@Casterk017`): Contains all PostgreSQL SQL migrations (schema, triggers, RLS, storage policies, RPCs, reference data), the `admin-accounts` Edge Function, and the idempotent `seed/seed.mjs` dummy-data script. See [`supabase/README.md`](supabase/README.md).
- `.gitignore` (Root): Prevents OS junk files, IDE configs (`.vscode/`, `.idea/`), and sensitive `.env` secret files from being committed anywhere in the repository.

### Mobile App Folders (`Android/`)

1. `Android/lib/UserDashboard/` (Owner: `@KaiSheng1030`): Mobile user landing screens (`UserDashboard.dart`), paginated report history, Top-20 + personal rank leaderboard, and two-mode chat interface.
2. `Android/lib/Map/` (Owner: `@HamsterSaMe`): Interactive UTS campus map widget, preset pin markers, privacy-safe pin report summaries, and on-demand GPS capture logic.
3. `Android/lib/Report/` (Owner: `@wongenxi`): Mobile incident report form (loading dynamic active categories) and multi-photo submission logic.
4. `Android/lib/Database/` (Owner: `@Casterk017`): Standardized Dart Supabase wrapper services, immutable models, Realtime helpers, and typed `DatabaseException` handling. See [`Android/lib/Database/README.md`](Android/lib/Database/README.md).

### Web Portal Folders (`Website/`)

1. `Website/src/AdminDashboard/` (Owner: `@JoeyHi`): Web interface for Department Admins and the Super Admin (login gating, analytics, dynamic category & pin/bounds management, account management, and multi-tier chat/moderation).
2. `Website/src/Report/` (Owner: `@wongenxi`): Web report list (paginated), Report Details view with audit timeline & signed photo URLs, and status resolution controls.
3. `Website/src/Database/` (Owner: `@Casterk017`): Strongly typed TypeScript Supabase wrapper services for the Vite web portal. See [`Website/src/Database/README.md`](Website/src/Database/README.md).

---

## 3. Main Features & Architecture

### A. Interactive Campus Map & Dynamic Pin Management

- **Preset Campus Pins (`preset_pins`):** Preloaded with 19 UTS campus locations (coordinates, block/section details, and public building photos stored in the `pin-images` bucket).
- **Privacy-Safe Pin Summaries (`get_pin_report_summaries`):** Tapping a map pin displays non-sensitive incident summaries (title, reported date, solved/unsolved status) without exposing reporter identities.
- **Super Admin Map Controls (`pinService`):** The Super Admin can add, edit, upload photos for (`uploadPinImage`), and delete obsolete campus pins (`deletePresetPin`). `reports.pin_id` uses `ON DELETE SET NULL` so historical reports remain intact via their `reports.location` text snapshot.
- **Expandable Campus Bounds (`campus_settings`):** UTS GPS boundaries are stored in a Super Admin-editable settings table (`getCampusBounds` / `updateCampusBounds`) rather than hardcoded, allowing campus coverage to expand without SQL migrations.

### B. Incident Reporting & GPS Trust Verification

- **Dynamic Category-to-Department Routing (`category_department_map`):** Report categories (`lighting`, `facilities`, `access`, `environment`, `parking`, `security`, plus any new categories added from the Super Admin Dashboard) dynamically route incoming reports to one of the 4 fixed admin departments (`facilities`, `cleaner`, `parking`, `security`) and can be toggled active/inactive without breaking historical records.
- **On-Demand GPS Trust Badge:** Optional reporter GPS coordinates (`reporter_lat`, `reporter_lng`) are verified server-side by a database trigger against `campus_settings` bounds to stamp `is_gps_verified`, without blocking students who submit reports after leaving campus or from areas with weak indoor GPS.
- **Private Multi-Photo Evidence (`report-attachments`):** Students can attach multiple photos per report, stored in a private bucket and served via short-lived, RBAC-gated signed URLs.
- **Paginated Report History & Audit Timeline (`report_updates`):** Reports generate sequential tracking codes (`UTS-1001`, etc.), log status transitions (`pending`, `in_progress`, `resolved`, `rejected`) with staff notes, and load newest-first in paginated batches of the **latest 10** (`limit = 10`, `offset = 0`) returning `{ items, totalCount, hasMore }`.

### C. Automated Contribution Ledger & Leaderboards

- **Append-Only Points Ledger (`contribution_events`):** When a report transitions to `resolved`, an idempotent database trigger automatically awards **+20 points** to the reporting student and **+10 points** to the resolving admin (`0` points for pending or rejected reports, preventing spam farming).
- **Top 20 + Personal Rank (`get_leaderboard` & `get_my_rank`):** Computes **Monthly** and **All-Time** rankings dynamically from timestamped ledger events (no manual monthly reset cron required), returning the **Top 20** alongside the logged-in user's exact rank even if outside the Top 20. The Super Admin also views department admin rankings.

### D. Two-Mode Real-Time Chat & Tiered Moderation

- **Mobile Chat (Strictly 2 Options):**
  1. **Community Chat (`Campus Safety Circle`):** A campus-wide real-time group chat for all users, with server-stamped sender aliases/role badges, user-level sender blocking (`chat_blocked_users`), and message flagging (`chat_message_reports`).
  2. **Department Admin Chat (`user_admin`):** Students select one of the 4 fixed departments (**Facilities**, **Cleaner**, **Parking**, or **Security** — strictly excluding Super Admin) via `get_or_create_department_chat` to open a direct support thread visible to all admins in that department and overseen by the Super Admin.
- **Web Portal Staff Chat & Tiered Moderation:** Includes private **Admin ↔ Super Admin** (`admin_super_admin`) channels on the web portal. Both Department Admins and the Super Admin can moderate and delete messages/flags in the **Community** chat, while **only the Super Admin** has moderation privilege (`DELETE` messages & review flags) on student–admin (`user_admin`) threads.

### E. Security, Account Provisioning & Password Recovery

- **Strict Database Isolation (`Database/` Wrappers):** All Supabase queries, Realtime subscriptions, and typed error handling (`DatabaseException`) are encapsulated inside `Android/lib/Database/` (Dart) and `Website/src/Database/` (TypeScript).
- **Privileged Account Management (`admin-accounts` Edge Function):** Mobile sign-ups are locked to `role = 'user'`; creating department admin accounts, hard-deleting accounts (`auth.admin.deleteUser` with `ON DELETE SET NULL` preserving campus history), listing all accounts, and triggering administrative password resets run server-side via a JWT-verified Edge Function, paired with self-service email password recovery on both mobile and web login screens.

---

## 4. Team Workflow & Local Setup

### Collaboration Rules

- **Stay in Your Assigned Folder & Branch:** Work on your feature branch (`UserDashboard`, `AdminDashboard`, `Map`, `Report`, `Database`) and only create/edit files inside your designated folder(s).
- **Use Only Wrapper Functions for Data:** Import from `Android/lib/Database/database.dart` (mobile) or `Website/src/Database` (web) — never run raw Supabase queries in UI files.
- **Never Commit Secrets:** Copy `.env.example` → `.env` locally (ignored by Git). Only use the public **anon** key in `Android/.env` and `Website/.env`; keep `SUPABASE_SERVICE_ROLE_KEY` strictly in `supabase/.env` for local seeding.
- **Merge via Pull Request:** Open a PR into `main` when ready; `.github/CODEOWNERS` enforces review by `@Casterk017` or `@HamsterSaMe`.

### Quick Start

#### 1. Clone the repository

```bash
git clone https://github.com/Casterk017/Mobile-App-Development-Assignment-Group-12.git
cd Mobile-App-Development-Assignment-Group-12
```

#### 2. Configure Environment Variables

- **Mobile:** Copy `Android/.env.example` → `Android/.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`)
- **Web:** Copy `Website/.env.example` → `Website/.env` (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`)
- **Backend Seed (Database Owner only):** Copy `supabase/.env.example` → `supabase/.env` (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`)

*(Use the base project URL `https://<project-ref>.supabase.co` without `/rest/v1/`.)*

#### 3. Run the Flutter Mobile App

```bash
cd Android
flutter pub get
flutter run
```

#### 4. Run the Admin Website (in a separate terminal)

```bash
cd Website
npm install
npm run typecheck
```

#### 5. Pre-Seeded Test Accounts (Default Password: `CampusSafe123!`)

- **Super Admin:** `superadmin@uts.edu.my`
- **Department Admins:** `facilities.admin@uts.edu.my`, `cleaner.admin@uts.edu.my`, `parking.admin@uts.edu.my`, `security.admin@uts.edu.my`
- **Students:** `fern@student.uts.edu.my`, `river@student.uts.edu.my`, `cedar@student.uts.edu.my`, `oak@student.uts.edu.my`, `iris@student.uts.edu.my`, `pine@student.uts.edu.my`

For Supabase CLI migration push, Edge Function deployment, and seeding commands, see [`supabase/README.md`](supabase/README.md).


#### 5. Pre-Seeded Test Accounts (Default Password: `CampusSafe123!`)

- **Super Admin:** `superadmin@uts.edu.my`
- **Department Admins:** `facilities.admin@uts.edu.my`, `cleaner.admin@uts.edu.my`, `parking.admin@uts.edu.my`, `security.admin@uts.edu.my`
- **Students:** `fern@student.uts.edu.my`, `river@student.uts.edu.my`, `cedar@student.uts.edu.my`, `oak@student.uts.edu.my`, `iris@student.uts.edu.my`, `pine@student.uts.edu.my`

For Supabase CLI migration push, Edge Function deployment, and seeding commands, see [`supabase/README.md`](supabase/README.md).