import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../widgets/campus_map_frame.dart';
import 'safety_help.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.username,
    this.onOpenSettings,
    this.onReportIncident,
    this.recentReport,
    this.helpContacts = const [],
    this.map,
    this.mapBuilder,
  }) : assert(map == null || mapBuilder == null);
  final String username;
  final VoidCallback? onReportIncident;
  final Widget? recentReport;
  final List<CampusHelpContact> helpContacts;
  final VoidCallback? onOpenSettings;
  final Widget? map;
  final WidgetBuilder? mapBuilder;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              LayoutBuilder(
                builder: (context, header) {
                  final enlarged =
                      MediaQuery.textScalerOf(context).scale(1) > 1.3;
                  final brand = Text(
                    'CampusSafe',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: enlarged ? 24 : 32,
                      letterSpacing: -1,
                    ),
                  );
                  final settings = IconButton(
                    key: const ValueKey('student-settings'),
                    onPressed: widget.onOpenSettings,
                    tooltip: s.t('settings'),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.settings_outlined),
                  );
                  if (enlarged) {
                    return Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: settings,
                        ),
                        Center(child: brand),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(child: brand),
                      settings,
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.t('welcome'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.username,
                      key: const ValueKey('dashboard-user-name'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('report-incident'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(s.t('reportIncident')),
                    onPressed:
                        widget.onReportIncident ??
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.t('reportNotConnected'))),
                        ),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('get-help'),
                    icon: const Icon(Icons.health_and_safety_outlined),
                    label: Text(s.t('getHelp')),
                    onPressed: () =>
                        showSafetyHelp(context, contacts: widget.helpContacts),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: math.max(360, constraints.maxHeight * .62),
                child: CampusMapFrame(
                  map: widget.map,
                  mapBuilder: widget.mapBuilder,
                ),
              ),
              const SizedBox(height: 20),
              if (widget.recentReport case final report?) ...[
                report,
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
