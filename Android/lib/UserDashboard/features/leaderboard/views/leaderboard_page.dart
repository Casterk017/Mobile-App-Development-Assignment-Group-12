import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../app/locale_controller.dart';
import '../models/leaderboard_entry_ui_model.dart';
import '../view_models/leaderboard_view_model.dart';
import '../widgets/leaderboard_entry_tile.dart';
import '../widgets/leaderboard_podium.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key, required this.viewModel});
  final LeaderboardViewModel viewModel;
  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: _RefreshRanking(
              vm: vm,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  StudentHeading(
                    eyebrow: s.t('positiveImpact'),
                    title: s.t('leaderboard'),
                    subtitle: s.t('rankingSubtitle'),
                  ),
                  SegmentedButton<RankingPeriod>(
                    segments: [
                      ButtonSegment(
                        value: RankingPeriod.monthly,
                        label: Text(s.t('monthly')),
                      ),
                      ButtonSegment(
                        value: RankingPeriod.allTime,
                        label: Text(s.t('allTime')),
                      ),
                    ],
                    selected: {vm.period},
                    onSelectionChanged: (value) => vm.setPeriod(value.first),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (vm.period == RankingPeriod.monthly &&
                          vm.month != null)
                        Text(
                          MaterialLocalizations.of(context)
                              .formatMonthYear(vm.month!),
                        ),
                      TextButton.icon(
                        key: const ValueKey('points-guide'),
                        icon: const Icon(Icons.info_outline),
                        label: Text(s.t('pointsGuide')),
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(s.t('pointsGuide')),
                            content: SingleChildScrollView(
                              child: Text(s.t('pointsGuideBody')),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(s.t('close')),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (vm.lastUpdated case final updated?)
                    Text(
                      '${s.t('lastUpdated')}: ${s.date(updated)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (vm.offline)
                    ListTile(
                      leading: const Icon(Icons.cloud_off_outlined),
                      title: Text(s.t('offline')),
                    ),
                  if (vm.loading && vm.hasData) const LinearProgressIndicator(),
                  if (vm.hasError && vm.hasData)
                    ListTile(
                      leading: const Icon(Icons.cloud_off_outlined),
                      title: Text(s.t('refreshFailed')),
                      trailing: IconButton(
                        tooltip: s.t('retry'),
                        onPressed: vm.refresh,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (vm.loading && !vm.hasData)
                    StudentStatePanel(
                      icon: Icons.leaderboard_outlined,
                      title: s.t('loadingRanking'),
                      message: '',
                      loading: true,
                    )
                  else if (vm.hasError && !vm.hasData)
                    StudentStatePanel(
                      icon: Icons.cloud_off,
                      title: s.t('loadError'),
                      message: s.t('tryAgain'),
                      action: s.t('retry'),
                      onAction: vm.loadRankings == null ? null : vm.refresh,
                    )
                  else ...[
                    if (vm.entries.isNotEmpty)
                      LeaderboardPodium(entries: vm.entries),
                    const SizedBox(height: 24),
                    Text(
                      s.t('yourPosition'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (vm.currentStudent case final current?)
                      LeaderboardEntryTile(
                        key: const ValueKey('current-student-ranking'),
                        entry: current,
                        highlight: true,
                      )
                    else
                      Text(s.t('notRanked')),
                    const SizedBox(height: 24),
                    Text(
                      s.t('communityRanking'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (vm.entries.isEmpty)
                      StudentStatePanel(
                        icon: Icons.people_outline,
                        title: s.t('noRanking'),
                        message: s.t('noRankingBody'),
                      ),
                    for (final entry in vm.entries) ...[
                      LeaderboardEntryTile(
                        entry: entry,
                        highlight: entry.studentId == vm.currentStudentId,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RefreshRanking extends StatelessWidget {
  const _RefreshRanking({required this.vm, required this.child});
  final LeaderboardViewModel vm;
  final Widget child;
  @override
  Widget build(BuildContext context) => vm.loadRankings == null
      ? child
      : RefreshIndicator(onRefresh: vm.refresh, child: child);
}
