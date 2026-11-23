import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../models/report_ui_model.dart';

class ReportStatusChip extends StatelessWidget {
  const ReportStatusChip({super.key, required this.report});
  final ReportUiModel report;
  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    final status = report.status;
    final key = switch (report.submissionState) {
      SubmissionState.failed => 'failed',
      SubmissionState.draft => 'draft',
      SubmissionState.submitted => status!.labelKey,
    };
    final color =
        status?.displayColor(context) ?? Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        s.t(key),
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class ReportHistoryCard extends StatelessWidget {
  const ReportHistoryCard({
    super.key,
    required this.report,
    required this.onTap,
  });
  final ReportUiModel report;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    report.id,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  ReportStatusChip(report: report),
                ],
              ),

              const SizedBox(height: 8),
              Text('${s.t(report.categoryKey)} · ${report.location}'),
              const SizedBox(height: 6),
              Text(
                s.date(report.displayDate),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (report.latestUpdate case final update?) ...[
                const Divider(height: 28),
                Text(
                  '${s.t('latestUpdate')} · ${s.date(update.at)}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(update.note, style: Theme.of(context).textTheme.bodySmall),
              ],
              if (report.hasAttachment) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        s.t('attachment'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
