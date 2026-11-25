# Campus Safety & Incident Reporting System

**Repository:** `Mobile-App-Development-Assignment-Group-12`

---

## 1. What This Project Is About

The **Campus Safety & Incident Reporting System** is a hybrid mobile and web application built for a Mobile App Development course assignment. It connects campus users on mobile devices with administrative staff on a web portal to streamline campus safety reporting, location verification, and incident resolution.

- **How It Works:** Mobile users log in, view their personal dashboard and contribution rankings, select preset pins on an interactive campus map (with on-demand GPS area verification), and submit incident reports. On the web portal, regular administrators review and resolve reports assigned to their specific role, while a Super Admin oversees global analytics, user/admin accounts, and all system-wide reports.
- **Architecture Strategy:** The repository uses a **decoupled monorepo** split into two independent client folders (`Android/` and `Website/`) backed by a shared cloud database. Every team member works inside an isolated feature folder and interacts with the database strictly through standardized wrapper functions (`Database/`), preventing merge conflicts and keeping UI code completely separated from backend queries.

### Tech Stack

- **Mobile Application (`Android/`):** Flutter (Dart)
- **Web Administration Portal (`Website/`):** JavaScript / TypeScript (Node.js web stack)
- **Backend, Auth & Security (`Database/`):** Cloud database with Role-Based Access Control (`user`, `admin`, `super_admin`), environment-variable secret management (`.env`), and pre-seeded dummy data for testing.

### Team Roles & Ownership

- Casterk017 - Project Architecture, Database Design, Security Rules & Cross-Platform Service Wrappers
- JoeyHi - Web Admin & Super Admin Dashboard UI
- Kaisheng1030 - Mobile User Dashboard UI & Analytics
- HamsterSaMe - Mobile Interactive Map, Preset Pins & GPS Location Verification
- wongenxi - Cross-Platform Incident Reporting (Mobile Submission & Web Display)

---

## 2. What Each Folder Is For

```text
Mobile-App-Development-Assignment/
├── .github/
│   └── CODEOWNERS
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
│   ├── .gitignore
│   └── pubspec.yaml
├── Website/
│   ├── src/
│   │   ├── AdminDashboard/
│   │   ├── Database/
│   │   └── Report/
│   └── .gitignore
├── .gitignore
└── README.md
```

### Root-Level Folders & Files

- `.github/`: Holds GitHub repository governance files, specifically `CODEOWNERS`, which enforces folder-level Pull Request review rules so teammates only modify their own modules.
- `Android/`: Contains the complete Flutter mobile application used by regular campus users.
- `Website/`: Contains the complete web portal used by regular administrators and the Super Admin.
- `.gitignore` (Root): Prevents OS junk files, IDE configs (`.vscode/`, `.idea/`), and sensitive `.env` secret files from being committed anywhere in the repository.

### Mobile App Folders (`Android/`)

1. `Android/lib/UserDashboard/` (Owner: `@KaiSheng1030`): Contains the mobile user landing screens (`UserDashboard.dart`), personal analytics displays, contribution leaderboards, and the user-to-admin chat interface.
2. `Android/lib/Map/` (Owner: `@HamsterSaMe`): Contains the interactive campus map widget, preset pin markers, on-demand GPS capture logic, and boundary-checking functions.
3. `Android/lib/Report/` (Owner: `@wongenxi`): Contains the mobile incident report form and submission logic that sends user reports tied to preset pins to the database.
4. `Android/lib/Database/` (Owner: `@Casterk017`): Contains the Dart database wrapper functions (GET, POST, UPDATE) and data model classes used by all mobile modules to communicate with the cloud backend.
5. `Android/android/`, `ios/`, `web/`, `test/`: Standard Flutter platform build wrappers and testing directories.

### Web Portal Folders (`Website/`)

- `Website/src/AdminDashboard/` (Owner: `@JoeyHi`): Contains the web interface for both regular admins and the Super Admin, including login gating, analytics panels, account management controls, and the multi-tier chat interface.
- `Website/src/Report/` (Owner: `@wongenxi`): Contains the web report retrieval components and the Report Details view embedded inside the Admin Dashboard.
- `Website/src/Database/` (Owner: `@Casterk017`): Contains the JavaScript/TypeScript database wrapper functions (GET, POST, UPDATE) that power data retrieval, account administration, and status updates on the website.

---

## 3. Main Features of the Project

### A. User Dashboard (Mobile — Supports Multiple Users)

- **Authentication Gate:** Integrates the login module before loading the dashboard so only authenticated users can access their account.
- **User Analytics & History:** Displays the total number of reports posted by the user, a list of reports submitted by that specific account, earned Community Contribution points, and the user's ranking based on their contribution points.
- **Embedded Campus Map:** Loads and renders the interactive campus map and its functions directly onto the user dashboard interface.
- **User-to-Admin Chat:** Provides an integrated chat module allowing users to communicate directly with a predetermined administrator.

### B. Admin Dashboard (Web — Supports Multiple Regular Admins & 1 Super Admin)

- **Authentication Gate:** Restricts access until an administrator or Super Admin successfully logs in via the authentication page.
- **Regular Admin Analytics:** Displays the administrator's assigned role, the total number of reports waiting to be resolved by them, and the total number of reports resolved by them.
- **Role-Filtered Report Section:** Displays incoming reports filtered specifically to the logged-in admin's role, paired with a Report Details button to inspect full incident information.
- **Multi-Tier Chat Module:** Allows regular administrators to chat with both the Super Admin and mobile users.
- **Super Admin Exclusive Capabilities:**
  - **Global Analytics & Rankings:** Displays system-wide totals of reports waiting to be resolved, system-wide totals of reports resolved, and contribution rankings for both admins and users.
  - **Account Management & Privacy-Preserving Recovery:** Views all user and admin accounts, deletes accounts when required, and assists with account recovery via email (facilitating password resets through email without exposing passwords or compromising user/admin privacy).
  - **Full System Report Access:** Grants visibility into all reports across the entire platform (unlike regular admins who only view reports assigned to their role).

### C. Interactive Map & Location Verification (Mobile)

- **Campus Map & Preset Pins:** Displays an interactive map of the campus populated with predefined preset pins that users tap and select when submitting an incident report.
- **On-Demand GPS Verification:** Captures the user's live GPS location on demand when a button is pressed and calculates whether the user is physically inside a specific designated area.

### D. Cross-Platform Incident Reporting (Mobile & Web)

- **Mobile Report Submission:** Links incident details to the user's selected preset pin on the map and pushes the validated report record to the cloud database.
- **Web Report Retrieval & Inspection:** Fetches stored reports from the database and renders summary lists and full detail modals/views inside the Admin Dashboard.

### E. Centralized Database, Wrapper Services & Security (Shared Backend)

- **Standardized Wrapper Functions:** All database reads, writes, and updates are encapsulated inside `Database/` on both platforms with fixed input parameters and return formats—UI modules never execute raw database queries directly.
- **Pre-Seeded Dummy Data:** Includes realistic dummy accounts (users, regular admins, Super Admin), preset pins, and sample reports so every module can be tested immediately.
- **Role-Based Access Control (RBAC):** Enforces database-level permissions separating `user`, `admin`, and `super_admin` privileges.

---

## 4. Team Workflow & Local Setup

### Collaboration Rules

- **Stay in Your Assigned Folder & Branch:** Work on your feature branch (e.g., `dev-user-dashboard`, `dev-admin-web`, `dev-map`, `dev-reporting`, `dev-database`) and only create/edit files inside your designated folder(s).
- **Use Only Wrapper Functions for Data:** Call the functions provided in `Database/` for all data operations.
- **Never Commit Secrets:** Place database keys in local `.env` files (ignored by Git).
- **Merge via Pull Request:** Open a PR into `main` when ready; `.github/CODEOWNERS` enforces review by `@Casterk017` or `@HamsterSaMe`.

### Quick Start

#### 1. Clone the repository

```bash
git clone [https://github.com/Casterk017/Mobile-App-Development-Assignment.git](https://github.com/Casterk017/Mobile-App-Development-Assignment.git)
cd Mobile-App-Development-Assignment
```

#### 2. Run the Flutter Mobile App

```bash
cd Android
flutter pub get
flutter run
```

#### 3. Run the Admin Website (in a separate terminal)

```bash
cd Website
npm install
npm run dev
```