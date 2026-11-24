import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_development_assignment_group_12/app/app_theme.dart';
import 'package:mobile_app_development_assignment_group_12/app/locale_controller.dart';
import 'package:mobile_app_development_assignment_group_12/app/student_preferences.dart';
import 'package:mobile_app_development_assignment_group_12/features/community_chat/view_models/community_chat_view_model.dart';
import 'package:mobile_app_development_assignment_group_12/features/community_chat/models/chat_message_ui_model.dart';
import 'package:mobile_app_development_assignment_group_12/features/community_chat/views/community_chat_page.dart';
import 'package:mobile_app_development_assignment_group_12/features/dashboard/views/dashboard_page.dart';
import 'package:mobile_app_development_assignment_group_12/features/language_settings/views/settings_page.dart';
import 'package:mobile_app_development_assignment_group_12/features/leaderboard/view_models/leaderboard_view_model.dart';
import 'package:mobile_app_development_assignment_group_12/features/leaderboard/views/leaderboard_page.dart';
import 'package:mobile_app_development_assignment_group_12/features/my_reports/view_models/my_reports_view_model.dart';
import 'package:mobile_app_development_assignment_group_12/features/my_reports/views/my_reports_page.dart';
import 'package:mobile_app_development_assignment_group_12/main.dart';

Future<void> pumpStudentApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    const RepaintBoundary(key: ValueKey('student-preview'), child: MyApp()),
  );
  await tester.pumpAndSettle();
}

/// Optional local screenshots for visual review; normal tests write no images.
Future<void> capturePreview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_STUDENT_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('student-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/student_previews');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Widget host(Widget child) => MaterialApp(
  theme: campusTheme(),
  localizationsDelegates: const [
    CampusStrings.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  setUpAll(() async {
    final fonts = FontLoader('LibreFranklin');
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      fonts.addFont(
        rootBundle.load(
          'assets/fonts/libre_franklin/LibreFranklin-$weight.ttf',
        ),
      );
    }
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('primary navigation preserves report filters and local chat', (
    tester,
  ) async {
    await pumpStudentApp(tester);
    expect(find.text('Your student space'), findsNothing);
    expect(find.byIcon(Icons.translate_outlined), findsNothing);
    expect(find.text('Edmund Chai En Yun'), findsOneWidget);
    expect(find.text('Welcome,'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
    await capturePreview(tester, 'home');
    expect(
      find.byKey(const ValueKey('campus-map-placeholder')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('nav-reports')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await capturePreview(tester, 'reports');
    await tester.tap(find.byKey(const ValueKey('quick-status-resolved')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-chat')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('chat-input')),
      'A fictional safety tip',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send-message')));
    await tester.pumpAndSettle();
    expect(find.text('A fictional safety tip'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('chat-input')))
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('Student 1'), findsOneWidget);
    expect(find.text('Department Admin'), findsOneWidget);
    expect(find.text('You'), findsWidgets);
    await capturePreview(tester, 'chat');
    await tester.tap(find.byKey(const ValueKey('nav-ranking')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All time'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('leaderboard-podium')), findsOneWidget);
    await capturePreview(tester, 'leaderboard');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('current-student-ranking')),
      200,
    );
    expect(find.text('590 points'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('nav-reports')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-status-resolved')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-chat')));
    await tester.pumpAndSettle();
    expect(find.text('A fictional safety tip'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Settings changes appearance across every page and follows the device',
    (tester) async {
      await pumpStudentApp(tester);
      await tester.tap(find.byKey(const ValueKey('student-settings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('theme-dark')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('theme-dark')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(
        Theme.of(tester.element(find.byKey(const ValueKey('theme-dark'))))
            .brightness,
        Brightness.dark,
      );
      await capturePreview(tester, 'settings_dark');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await capturePreview(tester, 'home_dark');
      for (final destination in ['reports', 'chat', 'ranking']) {
        await tester.tap(find.byKey(ValueKey('nav-$destination')));
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byKey(ValueKey('nav-$destination'))))
              .brightness,
          Brightness.dark,
        );
        await capturePreview(tester, '${destination}_dark');
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('student-settings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('theme-light')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('theme-light')));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byKey(const ValueKey('theme-light'))))
            .brightness,
        Brightness.light,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('theme-system')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('theme-system')));
      await tester.pumpAndSettle();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byKey(const ValueKey('theme-system'))))
            .brightness,
        Brightness.dark,
      );
    },
  );

  testWidgets('report search, compact filters and help states are usable', (
    tester,
  ) async {
    await pumpStudentApp(tester);
    await tester.tap(find.byKey(const ValueKey('report-incident')));
    await tester.pumpAndSettle();
    expect(
      find.text('Incident reporting is not connected yet.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('get-help')));
    await tester.pumpAndSettle();
    expect(find.text('Safety support'), findsOneWidget);
    expect(
      find.text('Verified campus contact details have not been supplied yet.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-reports')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('report-search')),
      'DEMO-106',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-filters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('status-null')), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.descendant(
        of: find.byType(MyReportsPage),
        matching: find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == 'DEMO-106',
        ),
      ),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: find.byType(MyReportsPage),
        matching: find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == 'DEMO-106',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(MyReportsPage),
        matching: find.text('DEMO-105'),
      ),
      findsNothing,
    );
  });

  testWidgets('name language and theme are restored after recreating the app', (
    tester,
  ) async {
    final data = <String, String>{};
    final store = StudentPreferences(
      studentId: 'one',
      readString: (key) async => data[key],
      writeString: (key, value) async {
        data[key] = value;
      },
    );
    await tester.pumpWidget(MyApp(preferences: store));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('student-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-display-name')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('display-name-input')),
      'Mint Owl',
    );
    await tester.tap(find.byKey(const ValueKey('save-display-name')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('theme-dark')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-dark')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('language-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-ms')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MyApp(preferences: store, initialPreferences: await store.load()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mint Owl'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.locale, const Locale('ms'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('history opens read-only report details', (tester) async {
    await pumpStudentApp(tester);
    await tester.tap(find.byKey(const ValueKey('nav-reports')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('DEMO-106'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('DEMO-106'));
    await tester.pumpAndSettle();
    expect(find.text('Report details'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'name edits validate and update Settings and Home for the session',
    (tester) async {
      await pumpStudentApp(tester);
      await tester.tap(find.byKey(const ValueKey('student-settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('edit-display-name')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('display-name-input')),
        '   ',
      );
      await tester.tap(find.byKey(const ValueKey('save-display-name')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your name.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('display-name-input')),
        '  Avery Tan  ',
      );
      await tester.tap(find.byKey(const ValueKey('save-display-name')));
      await tester.pumpAndSettle();
      expect(find.text('Avery Tan'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('dashboard-user-name')))
            .data,
        'Avery Tan',
      );
      await tester.tap(find.byKey(const ValueKey('student-settings')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('settings-user-name')))
            .data,
        'Avery Tan',
      );
      await tester.tap(find.byKey(const ValueKey('edit-display-name')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('display-name-input')),
        'Unsaved name',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('settings-user-name')))
            .data,
        'Avery Tan',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed host name saving keeps the original name and can be retried',
    (tester) async {
      final locale = LocaleController();
      addTearDown(locale.dispose);
      var attempts = 0;
      await tester.pumpWidget(
        host(
          StudentSettingsPage(
            username: 'Original name',
            localeController: locale,
            onNameChanged: (name) async {
              if (attempts++ == 0) {
                throw StateError('Demo host storage unavailable');
              }
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('edit-display-name')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('display-name-input')),
        'Updated name',
      );
      await tester.tap(find.byKey(const ValueKey('save-display-name')));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not save your name. Please try again.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('settings-user-name')))
            .data,
        'Original name',
      );
      await tester.tap(find.byKey(const ValueKey('save-display-name')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('settings-user-name')))
            .data,
        'Updated name',
      );
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new chat messages append below older messages and scroll to the bottom',
    (tester) async {
      final now = DateTime.now();
      final vm = CommunityChatViewModel(
        currentStudentId: 'me',
        currentAlias: 'You',
        messages: [
          for (var i = 0; i < 30; i++)
            ChatMessageUiModel(
              id: 'old-$i',
              senderId: 'student-1',
              senderAlias: 'Student 1',
              text: 'Earlier campus conversation $i. Keep the walkway clear.',
              sentAt: now.subtract(Duration(minutes: 30 - i)),
            ),
        ],
      );
      addTearDown(vm.dispose);
      await tester.pumpWidget(host(CommunityChatPage(viewModel: vm)));
      await tester.pumpAndSettle();
      final list = tester.widget<ListView>(
        find.byKey(const ValueKey('chat-message-list')),
      );
      list.controller!.jumpTo(0);
      await tester.pumpAndSettle();
      for (final message in ['First new message', 'Second new message']) {
        await tester.enterText(
          find.byKey(const ValueKey('chat-input')),
          message,
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('send-message')));
        await tester.pumpAndSettle();
      }
      expect(vm.messages.last.text, 'Second new message');
      expect(
        tester.getRect(find.text('First new message')).top,
        lessThan(tester.getRect(find.text('Second new message')).top),
      );
      expect(
        tester.getRect(find.text('Second new message')).bottom,
        lessThan(tester.getRect(find.byKey(const ValueKey('chat-input'))).top),
      );
      expect(list.controller!.position.extentAfter, lessThan(1));
      list.controller!.jumpTo(0);
      await tester.pumpAndSettle();
      vm.replaceMessages([
        ...vm.messages,
        ChatMessageUiModel(
          id: 'incoming',
          senderId: 'student-1',
          senderAlias: 'Student 1',
          text: 'An incoming message while reading history',
          sentAt: DateTime.now().add(const Duration(seconds: 1)),
        ),
      ]);
      await tester.pumpAndSettle();
      expect(list.controller!.position.pixels, 0);
      expect(find.byKey(const ValueKey('new-messages')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('new-messages')));
      await tester.pumpAndSettle();
      expect(list.controller!.position.extentAfter, lessThan(1));
      expect(
        find.text('An incoming message while reading history'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('language selection updates student shell and Material locale', (
    tester,
  ) async {
    await pumpStudentApp(tester);
    await tester.tap(find.byKey(const ValueKey('student-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Edmund Chai En Yun'), findsOneWidget);
    await capturePreview(tester, 'settings');
    await tester.tap(find.byKey(const ValueKey('language-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-ms')));
    await tester.pumpAndSettle();
    expect(find.text('Tetapan bahasa'), findsOneWidget);
    expect(
      Localizations.localeOf(tester.element(find.text('Tetapan bahasa')))
          .languageCode,
      'ms',
    );
    await tester.tap(find.byKey(const ValueKey('language-zh')));
    await tester.pumpAndSettle();
    expect(find.text('语言设置'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('首页'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unconnected sign out explains integration without leaving Settings',
    (tester) async {
      await pumpStudentApp(tester);
      await tester.tap(find.byKey(const ValueKey('student-settings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-sign-out')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-sign-out')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(
        find.text('Sign-out integration is not connected in this prototype.'),
        findsOneWidget,
      );
      expect(find.text('Settings'), findsOneWidget);
    },
  );

  testWidgets(
    'injected map stays replaceable and Settings invokes sign-out callback',
    (tester) async {
      var signedOut = false;
      await tester.pumpWidget(
        host(
          DashboardPage(
            username:
                'A very long fictional student display name for accessibility',
            mapBuilder: (_) => const Center(child: Text('Injected map')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Injected map'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Injected map'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('campus-map-placeholder')),
        findsNothing,
      );
      final locale = LocaleController();
      addTearDown(locale.dispose);
      await tester.pumpWidget(
        host(
          StudentSettingsPage(
            username: 'Demo student',
            localeController: locale,
            onSignOut: () async {
              signedOut = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-sign-out')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(signedOut, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Android back returns from a primary tab to Home', (
    tester,
  ) async {
    await pumpStudentApp(tester);
    await tester.tap(find.byKey(const ValueKey('nav-chat')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  for (final size in [
    const Size(320, 640),
    const Size(640, 360),
    const Size(900, 1000),
  ]) {
    testWidgets('all primary tabs support $size with enlarged text', (
      tester,
    ) async {
      await pumpStudentApp(tester, size: size, scale: 2);
      for (final key in [
        'nav-home',
        'nav-reports',
        'nav-chat',
        'nav-ranking',
      ]) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: key);
      }
    });
  }

  testWidgets('empty reports chat and ranking have useful states', (
    tester,
  ) async {
    final reports = MyReportsViewModel(currentStudentId: 'demo', reports: []);
    final chat = CommunityChatViewModel(
      currentStudentId: 'demo',
      currentAlias: 'Demo',
      messages: [],
    );
    final ranking = LeaderboardViewModel(
      currentStudentId: 'demo',
      rankings: const {},
    );
    addTearDown(reports.dispose);
    addTearDown(chat.dispose);
    addTearDown(ranking.dispose);
    await tester.pumpWidget(host(MyReportsPage(viewModel: reports)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('No successfully submitted reports'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No successfully submitted reports'), findsOneWidget);
    await tester.pumpWidget(host(CommunityChatPage(viewModel: chat)));
    await tester.pumpAndSettle();
    expect(find.text('Start a thoughtful conversation'), findsOneWidget);
    await tester.pumpWidget(host(LeaderboardPage(viewModel: ranking)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('No rankings yet'), 200);
    expect(find.text('No rankings yet'), findsOneWidget);
  });

  for (final language in ['ms', 'zh']) {
    testWidgets('small-phone enlarged text remains usable in $language', (
      tester,
    ) async {
      await pumpStudentApp(tester, size: const Size(320, 640), scale: 2);
      await tester.tap(find.byKey(const ValueKey('student-settings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('language-settings')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-settings')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('language-$language')),
        150,
      );
      await tester.ensureVisible(find.byKey(ValueKey('language-$language')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('language-$language')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .locale
            ?.languageCode,
        language,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      for (final key in [
        'nav-home',
        'nav-reports',
        'nav-chat',
        'nav-ranking',
      ]) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$language $key');
      }
    });
  }

  testWidgets(
    'tapping the chat composer opens and reopens the keyboard without message menu buttons',
    (tester) async {
      await pumpStudentApp(tester);
      await tester.tap(find.byKey(const ValueKey('nav-chat')));
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.byIcon(Icons.more_horiz), findsNothing);
      final composer = find.byKey(const ValueKey('chat-input'));
      await tester.tap(composer);
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(composer, 'Keep this draft');
      tester.testTextInput.hide();
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.tap(composer);
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
      expect(
        tester.widget<TextField>(composer).controller!.text,
        'Keep this draft',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('chat composer stays reachable with the keyboard visible', (
    tester,
  ) async {
    await pumpStudentApp(tester);
    await tester.tap(find.byKey(const ValueKey('nav-chat')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(find.byKey(const ValueKey('chat-input')));
    await tester.enterText(
      find.byKey(const ValueKey('chat-input')),
      'Keyboard layout demo',
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('chat-input'))).bottom,
      lessThanOrEqualTo(544),
    );
    await tester.tap(find.byKey(const ValueKey('send-message')));
    await tester.pumpAndSettle();
    expect(find.text('Keyboard layout demo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pulling past the scroll boundary does not stretch content', (
    tester,
  ) async {
    await pumpStudentApp(tester);
    final title = find.text('CampusSafe');
    final original = tester.getRect(title);
    final gesture = await tester.startGesture(const Offset(160, 260));
    await gesture.moveBy(const Offset(0, 180));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getRect(title), original);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('error state retry connects to supplied reports loader', (
    tester,
  ) async {
    final vm = MyReportsViewModel(
      currentStudentId: 'demo',
      reports: [],
      initialError: true,
      loadReports: () async => [],
    );
    addTearDown(vm.dispose);
    await tester.pumpWidget(host(MyReportsPage(viewModel: vm)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(vm.hasError, isFalse);
    expect(find.text('Overview'), findsOneWidget);
  });
}
