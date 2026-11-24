import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_theme.dart';
import 'app/locale_controller.dart';
import 'app/student_shell.dart';
import 'app/theme_controller.dart';
import 'app/student_preferences.dart';
import 'features/community_chat/mock/mock_messages.dart';
import 'features/community_chat/view_models/community_chat_view_model.dart';
import 'features/leaderboard/mock/mock_rankings.dart';
import 'features/leaderboard/view_models/leaderboard_view_model.dart';
import 'features/my_reports/mock/mock_reports.dart';
import 'features/my_reports/view_models/my_reports_view_model.dart';
import 'Map/features/campus_map/campus_map_entry.dart'; // YOUR MAP FEATURE

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Libre Franklin',
    ], await rootBundle.loadString('assets/fonts/libre_franklin/OFL.txt'));
  });
  StudentPreferences? preferences;
  var initial = const StudentPreferenceSnapshot();
  try {
    preferences = StudentPreferences.device(studentId: demoStudentId);
    initial = await preferences.load();
  } catch (_) {
    // Preference storage is optional; failure must not prevent app startup.
    debugPrint('CampusSafe preferences could not be restored.');
  }
  runApp(MyApp(preferences: preferences, initialPreferences: initial));
}

/// Prototype composition only. The team's authenticated app can instead host
/// StudentShell with real display data, ViewModels, and integration callbacks.
class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.preferences,
    this.initialPreferences = const StudentPreferenceSnapshot(),
  });
  final StudentPreferences? preferences;
  final StudentPreferenceSnapshot initialPreferences;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final LocaleController _locale;
  late final ThemeController _appearance;
  late String _displayName;
  @override
  void initState() {
    super.initState();
    _displayName =
        widget.initialPreferences.displayName ?? 'Edmund Chai En Yun';
    _locale = LocaleController(
      initialLocale: widget.initialPreferences.locale,
      savePreference: widget.preferences?.saveLocale,
    );
    _appearance = ThemeController(
      initialMode: widget.initialPreferences.themeMode,
      savePreference: widget.preferences?.saveTheme,
    );
  }

  Future<void> _saveName(String name) async {
    await widget.preferences?.saveName(name);
    if (mounted) setState(() => _displayName = name);
  }

  final _reports = MyReportsViewModel(
    currentStudentId: demoStudentId,
    reports: mockReports(),
  );
  final _chat = CommunityChatViewModel(
    currentStudentId: demoStudentId,
    currentAlias: 'You',
    messages: mockMessages(),
  );
  final _leaderboard = LeaderboardViewModel(
    currentStudentId: demoStudentId,
    rankings: mockRankings(),
    month: DateTime(2026, 11),
  );

  @override
  void dispose() {
    _locale.dispose();
    _appearance.dispose();
    _reports.dispose();
    _chat.dispose();
    _leaderboard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_locale, _appearance]),
    builder: (context, _) => MaterialApp(
      title: 'CampusSafe',
      debugShowCheckedModeBanner: false,
      theme: campusTheme(),
      darkTheme: campusTheme(brightness: Brightness.dark),
      themeMode: _appearance.mode,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
        physics: const ClampingScrollPhysics(),
      ),
      locale: _locale.locale,
      supportedLocales: LocaleController.supportedLocales,
      localizationsDelegates: const [
        CampusStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // We wrap StudentShell to easily float a testing button for your Map!
      home: Stack(
        children: [
          StudentShell(
            username: _displayName,
            onNameChanged: _saveName,
            localeController: _locale,
            themeController: _appearance,
            reportsViewModel: _reports,
            chatViewModel: _chat,
            leaderboardViewModel: _leaderboard,
          ),
          Positioned(
            bottom: 80,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: FloatingActionButton.extended(
                heroTag: "test_map_btn",
                onPressed: () {
                  // Calling the exact entry function you require!
                  CampusMapEntry.openMap(context);
                },
                icon: const Icon(Icons.map),
                label: const Text('Test Campus Map'),
              ),
            ),
          )
        ],
      ),
    ),
  );
}
