# Android Database Module (`Android/lib/Database/`)

Standardized Supabase wrapper services for the Flutter mobile app. UI modules (`UserDashboard/`, `Map/`, `Report/`) should call these wrappers instead of querying Supabase directly.

## 1. Local Setup

1. Copy `Android/.env.example` → `Android/.env` and fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
2. Ensure `.env` is listed under `flutter.assets` in `pubspec.yaml` (or pass credentials via `DatabaseConfig.initializeWithCredentials(...)`).
3. Initialize once in `main()`:

```dart
import 'package:mobile_app_development_assignment_group_12/Database/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseConfig.initialize();
  runApp(const MyApp());
}
```

## 2. Quick Usage by Module

### Map (`@HamsterSaMe`)
```dart
final pinService = PinService();
final pins = await pinService.getPresetPins();
final summaries = await pinService.getPinReportSummaries();
final bounds = await pinService.getCampusBounds();
```

### Reporting (`@wongenxi`)
```dart
final categoryService = CategoryService();
final categories = await categoryService.getActiveReportCategories();

final reportService = ReportService();
final created = await reportService.submitReport(
  pinId: 'pin_block_5',
  categoryKey: 'facilities',
  title: 'Loose handrail',
  location: 'UTS Block 5 · South stairs',
  description: 'Lower bracket is loose.',
  reporterLat: 2.340639,
  reporterLng: 111.844194,
  attachments: [ReportAttachmentUpload(fileName: 'photo.jpg', bytes: imageBytes)],
);
```

### UserDashboard (`@KaiSheng1030`)
```dart
// Paginated report history (defaults to latest 10, newest first)
final page = await ReportService().getMyReports(limit: 10, offset: 0);
// page.items, page.totalCount, page.hasMore

// Leaderboard (Top 20 + logged-in student's own rank even outside Top 20)
final leaderboard = LeaderboardService();
final top20 = await leaderboard.getStudentLeaderboard(DbRankingPeriod.monthly);
final myRank = await leaderboard.getMyStudentRank(DbRankingPeriod.monthly);

// Chat (strictly 2 mobile options: Community OR 1 of 4 Admin Departments)
final chat = ChatService();
final community = await chat.getCommunityChannel();
final facilitiesChat = await chat.getOrCreateDepartmentChat(AdminDepartment.facilities);
final messages = await chat.getMessages(community.id);
```

## 3. Error Handling

All wrappers throw `DatabaseException` with a machine-readable `code` and user-friendly `message`:

```dart
try {
  await AuthService().signIn(email: email, password: password);
} on DatabaseException catch (e) {
  debugPrint('${e.code}: ${e.message}');
}
```
