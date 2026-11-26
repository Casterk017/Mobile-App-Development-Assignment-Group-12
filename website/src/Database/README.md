# Website Database Module (`Website/src/Database/`)

Strongly typed TypeScript Supabase wrappers for the Web Admin & Super Admin Portal (`AdminDashboard/` and `Website/src/Report/`).

## 1. Local Setup

1. Copy `Website/.env.example` → `Website/.env` and fill in `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
2. Install dependencies inside `Website/`:
   ```bash
   cd Website
   npm install
   ```

## 2. Quick Usage by Role

```ts
import {
  authService,
  categoryService,
  pinService,
  reportService,
  accountService,
  leaderboardService,
  chatService,
} from '../Database';

// 1. Login gate (automatically rejects student accounts)
const profile = await authService.signInAdmin(email, password);

// 2. Paginated reports (defaults to latest 10, newest first; RLS auto-scopes by role)
const page = await reportService.getReports({ limit: 10, offset: 0 });
// page.items, page.totalCount, page.hasMore

// 3. Report details (includes status timeline + signed photo URLs)
const details = await reportService.getReportDetails(page.items[0].id);

// 4. Resolve a report (automatically awards +20 student / +10 admin points)
await reportService.updateReportStatus(reportId, 'resolved', 'Handrail tightened and verified.');

// 5. Super Admin: Dynamic category management
await categoryService.createCategoryMapping('wifi', 'Campus Wi-Fi Outage', 'facilities');
await categoryService.updateCategoryDepartment('wifi', 'facilities');
await categoryService.toggleCategoryActive('wifi', false);

// 6. Super Admin: Pin management & expandable campus bounds
const imageUrl = await pinService.uploadPinImage(file, 'pin_block_5');
await pinService.deletePresetPin('pin_old_shed');
await pinService.updateCampusBounds({ minLat: 2.339, maxLat: 2.3435, minLng: 111.841, maxLng: 111.851 });

// 7. Super Admin: Account management (Edge Function `admin-accounts`)
const accounts = await accountService.listAllAccounts();
await accountService.sendAccountRecoveryEmail('student@student.uts.edu.my');

// 8. Chat & Moderation
const deptThreads = await chatService.getDepartmentStudentChats(); // Super Admin can pass 'facilities' etc.
await chatService.deleteMessage(messageId); // Admin: community only; Super Admin: community + user_admin
```
