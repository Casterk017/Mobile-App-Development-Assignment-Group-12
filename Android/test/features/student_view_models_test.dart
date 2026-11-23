import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_development_assignment_group_12/app/theme_controller.dart';
import 'package:mobile_app_development_assignment_group_12/app/student_preferences.dart';
import 'package:mobile_app_development_assignment_group_12/app/locale_controller.dart';
import 'package:mobile_app_development_assignment_group_12/features/community_chat/view_models/community_chat_view_model.dart';
import 'package:mobile_app_development_assignment_group_12/features/leaderboard/mock/mock_rankings.dart';
import 'package:mobile_app_development_assignment_group_12/features/leaderboard/models/leaderboard_entry_ui_model.dart';
import 'package:mobile_app_development_assignment_group_12/features/leaderboard/view_models/leaderboard_view_model.dart';
import 'package:mobile_app_development_assignment_group_12/features/my_reports/mock/mock_reports.dart';
import 'package:mobile_app_development_assignment_group_12/features/my_reports/models/report_ui_model.dart';
import 'package:mobile_app_development_assignment_group_12/features/my_reports/view_models/my_reports_view_model.dart';

void main() {
  test(
    'preferences survive reloading and names are isolated by student',
    () async {
      final data = <String, String>{};
      StudentPreferences store(String student) => StudentPreferences(
        studentId: student,
        readString: (key) async => data[key],
        writeString: (key, value) async {
          data[key] = value;
        },
      );
      final preferences = store('one');
      await preferences.saveName('Mint Owl');
      await preferences.saveLocale(const Locale('ms'));
      await preferences.saveTheme(ThemeMode.dark);
      final restored = await store('one').load();
      expect(restored.displayName, 'Mint Owl');
      expect(restored.locale, const Locale('ms'));
      expect(restored.themeMode, ThemeMode.dark);
      expect((await store('two').load()).displayName, isNull);
      // Appearance and language belong to the device, not the account.
      expect((await store('two').load()).themeMode, ThemeMode.dark);
      data['campussafe.ui.theme'] = 'invalid';
      data['campussafe.ui.language'] = 'invalid';
      data['campussafe.student.one.displayName'] = '   ';
      final recovered = await store('one').load();
      expect(recovered.displayName, isNull);
      expect(recovered.locale, const Locale('en'));
      expect(recovered.themeMode, ThemeMode.system);
    },
  );
  test('failed refresh preserves existing reports and rankings', () async {
    final reports = MyReportsViewModel(
      currentStudentId: demoStudentId,
      reports: mockReports(),
      loadReports: () async => throw StateError('offline'),
    );
    final rankings = LeaderboardViewModel(
      currentStudentId: demoStudentId,
      rankings: mockRankings(),
      loadRankings: () async => throw StateError('offline'),
    );
    addTearDown(reports.dispose);
    addTearDown(rankings.dispose);
    await reports.refresh();
    await rankings.refresh();
    expect(reports.hasError, isTrue);
    expect(reports.studentReports.length, 6);
    expect(rankings.hasError, isTrue);
    expect(rankings.entries, isNotEmpty);
  });

  test(
    'failed appearance persistence retains the previous selection',
    () async {
      final modes = <ThemeMode>[];
      var fail = true;
      final controller = ThemeController(
        savePreference: (mode) async {
          if (fail) throw StateError('storage');
          modes.add(mode);
        },
      );
      addTearDown(controller.dispose);
      await expectLater(controller.select(ThemeMode.dark), throwsStateError);
      expect(controller.mode, ThemeMode.system);
      expect(controller.saving, isFalse);
      fail = false;
      await controller.select(ThemeMode.dark);
      expect(controller.mode, ThemeMode.dark);
      expect(modes, [ThemeMode.dark]);
    },
  );
  test(
    'search is case insensitive, scopes analytics, and clears with filters',
    () {
      final vm = MyReportsViewModel(
        currentStudentId: demoStudentId,
        reports: mockReports(),
      );
      addTearDown(vm.dispose);
      vm.setQuery('  demo-106  ');
      expect(vm.visibleReports.single.id, 'DEMO-106');
      vm.setQuery('no matching reports');
      expect(vm.resolutionPercentage, isNull);
      vm.clearFilters();
      expect(vm.visibleReports.length, 6);
      expect(vm.studentReports.length, 6);
    },
  );

  group('Report presentation rules', () {
    late MyReportsViewModel vm;
    setUp(
      () => vm = MyReportsViewModel(
        currentStudentId: demoStudentId,
        reports: mockReports(),
      ),
    );
    tearDown(() => vm.dispose());

    test('resolution includes rejected reports and excludes failed attempts and drafts', () {
      vm.replaceReports([
        ...mockReports(),
        ReportUiModel(
          id: 'failed',
          studentId: demoStudentId,
          title: 'Not submitted',
          categoryKey: 'lighting',
          location: 'Demo path',
          description: 'Fictional failure',
          createdAt: DateTime(2026, 11, 22),
          submissionState: SubmissionState.failed,
        ),
        ReportUiModel(
          id: 'draft',
          studentId: demoStudentId,
          title: 'Draft',
          categoryKey: 'lighting',
          location: 'Demo path',
          description: 'Fictional draft',
          createdAt: DateTime(2026, 11, 22),
          submissionState: SubmissionState.draft,
        ),
      ]);
      expect(vm.visibleReports, hasLength(8));
      expect(vm.submittedReports, hasLength(6));
      expect(vm.count(ReportStatus.rejected), 1);
      expect(vm.resolutionPercentage, 50);
    });

    test('empty denominator has no percentage', () {
      vm.replaceReports([]);
      expect(vm.resolutionPercentage, isNull);
    });

    test(
      'records for a different student do not enter history or analytics',
      () {
        vm.replaceReports([
          ReportUiModel(
            id: 'other',
            studentId: 'different-student',
            title: 'Private',
            categoryKey: 'facilities',
            location: 'Demo',
            description: 'Not current student',
            createdAt: DateTime(2026),
            submittedAt: DateTime(2026),
            status: ReportStatus.resolved,
          ),
        ]);
        expect(vm.visibleReports, isEmpty);
        expect(vm.resolutionPercentage, isNull);
      },
    );

    test('status and category filters also scope analytics', () {
      vm.setStatus(ReportStatus.resolved);
      expect(vm.visibleReports, hasLength(3));
      expect(vm.resolutionPercentage, 100);
      vm.setCategory('facilities');
      expect(vm.visibleReports.single.id, 'DEMO-101');
      vm.clearFilters();
      expect(vm.visibleReports, hasLength(6));
    });

    test('date range is inclusive and sorting changes history order', () {
      vm.setDateRange(
        DateTimeRange(
          start: DateTime(2026, 11, 17),
          end: DateTime(2026, 11, 19),
        ),
      );
      expect(vm.visibleReports.map((r) => r.id), ['DEMO-105', 'DEMO-104']);
      vm.setSort(ReportSort.oldest);
      expect(vm.visibleReports.map((r) => r.id), ['DEMO-104', 'DEMO-105']);
    });

    test('a failed technical attempt cannot carry a processing status', () {
      expect(
        () => ReportUiModel(
          id: 'bad',
          studentId: demoStudentId,
          title: 'Bad',
          categoryKey: 'lighting',
          location: 'Demo',
          description: 'Demo',
          createdAt: DateTime(2026),
          submissionState: SubmissionState.failed,
          status: ReportStatus.pending,
        ),
        throwsArgumentError,
      );
    });

    test(
      'loading failure can be retried without deleting existing reports',
      () async {
        var attempts = 0;
        final loader = MyReportsViewModel(
          currentStudentId: demoStudentId,
          reports: mockReports(),
          loadReports: () async {
            if (attempts++ == 0) throw StateError('Demo service offline');
            return [];
          },
        );
        addTearDown(loader.dispose);
        await loader.refresh();
        expect(loader.hasError, isTrue);
        expect(loader.visibleReports, hasLength(6));
        await loader.refresh();
        expect(loader.hasError, isFalse);
        expect(loader.visibleReports, isEmpty);
      },
    );
  });

  group('Local chat boundaries', () {
    test(
      'blank messages are rejected and sending adds one local message',
      () async {
        final vm = CommunityChatViewModel(
          currentStudentId: demoStudentId,
          currentAlias: 'Quiet Oak',
          messages: [],
        );
        addTearDown(vm.dispose);
        expect(await vm.send('   '), isFalse);
        expect(await vm.send('  A constructive demo tip  '), isTrue);
        expect(vm.messages.single.text, 'A constructive demo tip');
        expect(vm.demoMode, isTrue);
      },
    );

    test(
      'callback failure does not create a falsely delivered message',
      () async {
        final vm = CommunityChatViewModel(
          currentStudentId: demoStudentId,
          currentAlias: 'Quiet Oak',
          messages: [],
          sendMessage: (_) async => throw StateError('offline'),
        );
        addTearDown(vm.dispose);
        expect(await vm.send('Demo message'), isFalse);
        expect(vm.messages, isEmpty);
        expect(vm.sending, isFalse);
      },
    );

    test('in-flight requests finish safely after host disposal', () async {
      final pending = Completer<List<ReportUiModel>>();
      final vm = MyReportsViewModel(
        currentStudentId: demoStudentId,
        reports: [],
        loadReports: () => pending.future,
      );
      final loading = vm.refresh();
      expect(vm.loading, isTrue);
      vm.dispose();
      pending.complete(mockReports());
      await loading;
    });
  });

  group('Ranking contract', () {
    test(
      'periods supply distinct results and retain service-supplied scores',
      () {
        final vm = LeaderboardViewModel(
          currentStudentId: demoStudentId,
          rankings: mockRankings(),
        );
        addTearDown(vm.dispose);
        expect(vm.currentStudent!.rank, 4);
        expect(vm.currentStudent!.points, 120);
        vm.setPeriod(RankingPeriod.allTime);
        expect(vm.currentStudent!.rank, 6);
        expect(vm.currentStudent!.points, 590);
      },
    );
    test('current student can be outside the visible ranking list', () {
      final vm = LeaderboardViewModel(
        currentStudentId: demoStudentId,
        rankings: const {},
        currentStudentEntries: const {
          RankingPeriod.monthly: LeaderboardEntryUiModel(
            studentId: demoStudentId,
            rank: 42,
            alias: 'Quiet Oak',
            points: 10,
            verifiedContributions: 1,
          ),
        },
      );
      addTearDown(vm.dispose);
      expect(vm.entries, isEmpty);
      expect(vm.currentStudent!.rank, 42);
    });
  });

  group('Locale selection', () {
    test('all student strings have three nonempty translations', () {
      for (final entry in CampusStrings.translations.entries) {
        expect(entry.value, hasLength(3), reason: entry.key);
        expect(
          entry.value.every((value) => value.trim().isNotEmpty),
          isTrue,
          reason: entry.key,
        );
      }
    });
    test(
      'session locale updates and failed persistence retains previous locale',
      () async {
        final session = LocaleController();
        addTearDown(session.dispose);
        await session.select(const Locale('ms'));
        expect(session.locale, const Locale('ms'));
        expect(session.persistsPreference, isFalse);
        final persisted = LocaleController(
          savePreference: (_) async => throw StateError('storage unavailable'),
        );
        addTearDown(persisted.dispose);
        await expectLater(
          persisted.select(const Locale('zh')),
          throwsStateError,
        );
        expect(persisted.locale, const Locale('en'));
        expect(persisted.saving, isFalse);
      },
    );
  });
}
