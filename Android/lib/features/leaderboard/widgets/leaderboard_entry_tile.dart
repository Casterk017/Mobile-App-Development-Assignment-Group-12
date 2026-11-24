import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../models/leaderboard_entry_ui_model.dart';

class LeaderboardEntryTile extends StatelessWidget {
  const LeaderboardEntryTile({
    super.key,
    required this.entry,
    this.highlight = false,
  });
  final LeaderboardEntryUiModel entry;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    final foreground = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final medal = switch (entry.rank) {
      1 => const Color(0xFFE8C773),
      2 => const Color(0xFFDDE6E3),
      3 => const Color(0xFFD5B799),
      _ => Theme.of(context).colorScheme.primaryContainer,
    };
    return Container(
      decoration: BoxDecoration(
        color: highlight
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
              constraints.maxWidth < 260;
          final score = Text(
            '${entry.points} ${s.t('points')}',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: medal,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '#${entry.rank}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: entry.rank <= 3
                        ? const Color(0xFF263B2B)
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.alias,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${entry.verifiedContributions} ${s.t('contributions')}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: muted),
                    ),
                    if (compact) ...[const SizedBox(height: 8), score],
                  ],
                ),
              ),
              if (!compact) ...[const SizedBox(width: 12), score],
            ],
          );
        },
      ),
    );
  }
}
