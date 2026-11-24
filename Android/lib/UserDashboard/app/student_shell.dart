import 'package:flutter/material.dart';

import '../features/community_chat/view_models/community_chat_view_model.dart';
import '../features/community_chat/views/community_chat_page.dart';
import '../features/dashboard/views/dashboard_page.dart';
import '../features/language_settings/views/settings_page.dart';
import '../features/leaderboard/view_models/leaderboard_view_model.dart';
import '../features/leaderboard/views/leaderboard_page.dart';
import '../features/my_reports/view_models/my_reports_view_model.dart';
import '../features/my_reports/views/my_reports_page.dart';
import 'locale_controller.dart';
import 'theme_controller.dart';
import '../features/dashboard/views/safety_help.dart';
import '../features/my_reports/views/report_details_page.dart';
import '../features/my_reports/widgets/report_history_card.dart';

/// Reusable authenticated landing surface. No authentication or service setup.
/// ViewModels and locale controller are host-owned and are never disposed here.
class StudentShell extends StatefulWidget {
  const StudentShell({
    super.key,
    required this.username,
    required this.localeController,
    required this.reportsViewModel,
    required this.chatViewModel,
    required this.leaderboardViewModel,
    this.themeController,
    this.onReportIncident,
    this.helpContacts = const [],
    this.onSignOut,
    this.onNameChanged,
    this.map,
    this.mapBuilder,
  }) : assert(map == null || mapBuilder == null);
  final String username;
  final ThemeController? themeController;
  final VoidCallback? onReportIncident;
  final List<CampusHelpContact> helpContacts;
  final LocaleController localeController;
  final MyReportsViewModel reportsViewModel;
  final CommunityChatViewModel chatViewModel;
  final LeaderboardViewModel leaderboardViewModel;
  final Future<void> Function()? onSignOut;

  /// Optional host persistence; without it, name edits last for this session.
  final Future<void> Function(String name)? onNameChanged;
  final Widget? map;
  final WidgetBuilder? mapBuilder;
  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;
  late String _displayName;

  @override
  void initState() {
    super.initState();
    _displayName = widget.username;
  }

  @override
  void didUpdateWidget(covariant StudentShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) _displayName = widget.username;
  }

  Future<void> _changeName(String name) async {
    await widget.onNameChanged?.call(name);
    if (mounted) setState(() => _displayName = name);
  }

  void _navigate(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _index = index);
  }

  void _openSettings() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentSettingsPage(
          username: _displayName,
          localeController: widget.localeController,
          themeController: widget.themeController,
          helpContacts: widget.helpContacts,
          onSignOut: widget.onSignOut,
          onNameChanged: _changeName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    return PopScope<Object?>(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _index != 0) _navigate(0);
      },
      child: Scaffold(
        appBar: _index == 0
            ? null
            : AppBar(
                toolbarHeight: 56,
                title: Text(
                  s.t(['home', 'reports', 'chat', 'ranking'][_index]),
                ),
                actions: [
                  IconButton(
                    key: const ValueKey('student-settings'),
                    tooltip: s.t('settings'),
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: _openSettings,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
        body: SafeArea(
          top: _index == 0,
          child: IndexedStack(
            index: _index,
            children: [
              ListenableBuilder(
                listenable: widget.reportsViewModel,
                builder: (context, _) {
                  final reports =
                      widget.reportsViewModel.studentReports.toList()..sort(
                        (a, b) => (b.latestUpdate?.at ?? b.displayDate)
                            .compareTo(a.latestUpdate?.at ?? a.displayDate),
                      );
                  return DashboardPage(
                    username: _displayName,
                    onOpenSettings: _openSettings,
                    onReportIncident: widget.onReportIncident,
                    helpContacts: widget.helpContacts,
                    recentReport: reports.isEmpty
                        ? null
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.t('latestReport'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              ReportHistoryCard(
                                report: reports.first,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ReportDetailsPage(
                                      report: reports.first,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    map: widget.map,
                    mapBuilder: widget.mapBuilder,
                  );
                },
              ),
              MyReportsPage(viewModel: widget.reportsViewModel),
              CommunityChatPage(viewModel: widget.chatViewModel),
              LeaderboardPage(viewModel: widget.leaderboardViewModel),
            ],
          ),
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            selectedIndex: _index,
            height: largeText ? 100 : 80,
            labelBehavior: largeText
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: _navigate,
            destinations: [
              NavigationDestination(
                key: const ValueKey('nav-home'),
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: s.t('home'),
              ),
              NavigationDestination(
                key: const ValueKey('nav-reports'),
                icon: const Icon(Icons.description_outlined),
                selectedIcon: const Icon(Icons.description_rounded),
                label: s.t('reports'),
              ),
              NavigationDestination(
                key: const ValueKey('nav-chat'),
                icon: const Icon(Icons.forum_outlined),
                selectedIcon: const Icon(Icons.forum_rounded),
                label: s.t('chat'),
              ),
              NavigationDestination(
                key: const ValueKey('nav-ranking'),
                icon: const Icon(Icons.leaderboard_outlined),
                selectedIcon: const Icon(Icons.leaderboard_rounded),
                label: s.t('ranking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
