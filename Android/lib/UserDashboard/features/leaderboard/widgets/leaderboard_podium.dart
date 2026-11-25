import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../models/leaderboard_entry_ui_model.dart';
import 'leaderboard_entry_tile.dart';

class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({super.key, required this.entries});
  final List<LeaderboardEntryUiModel> entries;

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    final leaders = entries.where((entry) => entry.rank <= 3).toList();
    if (leaders.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('leaderboard-podium'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFE8C773)
                    : const Color(0xFF675022),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.t('topContributors'),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final complete = [1, 2, 3].every(
                (rank) =>
                    leaders.where((item) => item.rank == rank).length == 1,
              );
              if (!complete ||
                  constraints.maxWidth < 260 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                return Column(
                  children: [
                    for (final entry in leaders)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LeaderboardEntryTile(entry: entry),
                      ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final rank in [2, 1, 3])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _PodiumPlace(
                          entry: leaders.firstWhere(
                            (item) => item.rank == rank,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({required this.entry});
  final LeaderboardEntryUiModel entry;

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    final winner = entry.rank == 1;
    final medal = switch (entry.rank) {
      1 => const Color(0xFFE8C773),
      2 => const Color(0xFFDDE6E3),
      _ => const Color(0xFFD5B799),
    };
    final initials = entry.alias
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => String.fromCharCode(word.runes.first))
        .join()
        .toUpperCase();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (winner)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Icon(
              Icons.emoji_events_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFE8C773)
                  : const Color(0xFF866315),
              size: 28,
            ),
          )
        else
          const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: medal, width: 3),
          ),
          child: CircleAvatar(
            radius: winner ? 27 : 23,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            child: Text(
              initials,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Tooltip(
          message: entry.alias,
          child: Text(
            entry.alias,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${entry.points}',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(s.t('points'), style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 12),
        Container(
          constraints: BoxConstraints(
            minHeight: winner
                ? 78
                : entry.rank == 2
                ? 58
                : 42,
          ),
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: medal,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Text(
            '#${entry.rank}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF263B2B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
