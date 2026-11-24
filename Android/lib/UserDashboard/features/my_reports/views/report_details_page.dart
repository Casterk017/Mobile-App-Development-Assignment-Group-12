import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../models/report_ui_model.dart';
import '../widgets/report_history_card.dart';

class ReportDetailsPage extends StatelessWidget {
  const ReportDetailsPage({super.key, required this.report});
  final ReportUiModel report;

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    final updates = report.updates.toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    return Scaffold(
      appBar: AppBar(title: Text(s.t('reportDetails'))),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(report.id, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              Text(
                report.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: ReportStatusChip(report: report),
              ),
              const SizedBox(height: 24),
              _Detail(label: s.t('description'), value: report.description),
              _Detail(label: s.t('category'), value: s.t(report.categoryKey)),
              _Detail(label: s.t('location'), value: report.location),
              if (report.submittedAt case final time?)
                _Detail(
                  label: s.t('submittedAt'),
                  value: s.date(time, showZone: true),
                ),
              _Detail(
                label: s.t('attachment'),
                value: report.hasAttachment
                    ? s.t('attachmentDemo')
                    : s.t('noAttachment'),
              ),
              if (updates.isNotEmpty) ...[
                Text(
                  s.t('timeline'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                for (final (index, update) in updates.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: index == 0
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              switch (update.status) {
                                ReportStatus.pending => Icons.schedule_outlined,
                                ReportStatus.inProgress =>
                                  Icons.engineering_outlined,
                                ReportStatus.resolved => Icons.task_alt,
                                ReportStatus.rejected => Icons.info_outline,
                              },
                              color: index == 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.t(update.status.labelKey),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s.date(update.at, showZone: true),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(update.note),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(value),
      ],
    ),
  );
}
