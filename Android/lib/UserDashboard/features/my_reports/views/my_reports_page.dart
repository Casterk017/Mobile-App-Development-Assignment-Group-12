import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../app/locale_controller.dart';
import '../models/report_ui_model.dart';
import '../view_models/my_reports_view_model.dart';
import '../widgets/report_history_card.dart';
import 'report_details_page.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key, required this.viewModel});

  /// Externally owned: the host disposes the ViewModel.
  final MyReportsViewModel viewModel;
  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  int _tab = 1;
  final _search = TextEditingController();
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    _scrollController.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = CampusStrings.of(context);
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        if (vm.loading && !vm.hasData) {
          return StudentStatePanel(
            icon: Icons.description_outlined,
            title: s.t('loadReports'),
            message: '',
            loading: true,
          );
        }
        if (vm.hasError && !vm.hasData) {
          return SingleChildScrollView(
            child: StudentStatePanel(
              icon: Icons.cloud_off_outlined,
              title: s.t('loadError'),
              message: s.t('tryAgain'),
              action: s.t('retry'),
              onAction: vm.loadReports == null ? null : vm.refresh,
            ),
          );
        }
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: _RefreshReports(
              vm: vm,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  StudentHeading(
                    eyebrow: s.t('reports'),
                    title: s.t('reportsTitle'),
                    subtitle: s.t('reportsSubtitle'),
                  ),
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(value: 0, label: Text(s.t('overview'))),
                      ButtonSegment(value: 1, label: Text(s.t('history'))),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (selection) =>
                        setState(() => _tab = selection.first),
                  ),
                  const SizedBox(height: 24),
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
                  if (vm.loading) const LinearProgressIndicator(),
                  if (vm.hasError)
                    ListTile(
                      leading: const Icon(Icons.cloud_off_outlined),
                      title: Text(s.t('refreshFailed')),
                      trailing: IconButton(
                        tooltip: s.t('retry'),
                        onPressed: vm.refresh,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  TextField(
                    key: const ValueKey('report-search'),
                    controller: _search,
                    onChanged: vm.setQuery,
                    decoration: InputDecoration(
                      hintText: s.t('searchReports'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: s.t('clearFilters'),
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          vm.setQuery('');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        key: const ValueKey('quick-status-all'),
                        label: Text(s.t('all')),
                        selected: vm.status == null,
                        onSelected: (_) => vm.setStatus(null),
                      ),
                      for (final status in ReportStatus.values)
                        ChoiceChip(
                          key: ValueKey('quick-status-${status.name}'),
                          label: Text(s.t(status.labelKey)),
                          selected: vm.status == status,
                          onSelected: (_) => vm.setStatus(status),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    children: [
                      Text(
                        '${vm.visibleReports.length} ${s.t('matchingReports')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('report-filters'),
                        icon: const Icon(Icons.tune),
                        label: Text(s.t('filters')),
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(s.t('filters')),
                            content: SizedBox(
                              width: 680,
                              child: SingleChildScrollView(
                                child: ListenableBuilder(
                                  listenable: vm,
                                  builder: (context, _) => _ReportFilters(
                                    vm: vm,
                                    onClear: () {
                                      _search.clear();
                                      vm.clearFilters();
                                    },
                                  ),
                                ),
                              ),
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
                  const SizedBox(height: 20),
                  if (_tab == 0)
                    _ReportOverview(vm: vm)
                  else ...[
                    if (vm.visibleReports.isEmpty)
                      StudentStatePanel(
                        icon: Icons.inbox_outlined,
                        title: s.t('noReports'),
                        message: s.t('noReportsBody'),
                        action: s.t('clearFilters'),
                        onAction: () {
                          _search.clear();
                          vm.clearFilters();
                        },
                      ),
                    for (final report in vm.visibleReports) ...[
                      ReportHistoryCard(
                        report: report,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReportDetailsPage(report: report),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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

class _ReportFilters extends StatelessWidget {
  const _ReportFilters({required this.vm, required this.onClear});
  final VoidCallback onClear;
  final MyReportsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    final range = vm.dateRange;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.t('filters'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 600
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: width,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('status-${vm.status}'),
                        initialValue: vm.status?.name ?? 'all',
                        isExpanded: true,
                        decoration: InputDecoration(labelText: s.t('status')),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(s.t('all')),
                          ),
                          for (final status in ReportStatus.values)
                            DropdownMenuItem(
                              value: status.name,
                              child: Text(
                                s.t(status.labelKey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => vm.setStatus(
                          value == 'all'
                              ? null
                              : ReportStatus.values.byName(value!),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('category-${vm.category}'),
                        initialValue: vm.category ?? 'all',
                        isExpanded: true,
                        decoration: InputDecoration(labelText: s.t('category')),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(s.t('all')),
                          ),
                          for (final category in vm.categories)
                            DropdownMenuItem(
                              value: category,
                              child: Text(
                                s.t(category),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) =>
                            vm.setCategory(value == 'all' ? null : value),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: DropdownButtonFormField<ReportSort>(
                        key: ValueKey('sort-${vm.sort}'),
                        initialValue: vm.sort,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: s.t('sort')),
                        items: [
                          for (final sort in ReportSort.values)
                            DropdownMenuItem(
                              value: sort,
                              child: Text(
                                s.t(
                                  sort == ReportSort.newest
                                      ? 'newest'
                                      : 'oldest',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => vm.setSort(value!),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(
                    range == null
                        ? s.t('dateRange')
                        : '${s.date(range.start, time: false)} – ${s.date(range.end, time: false)}',
                  ),
                  onPressed: () async {
                    final selected = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100, 12, 31),
                      initialDateRange: range,
                    );
                    if (context.mounted && selected != null) {
                      vm.setDateRange(selected);
                    }
                  },
                ),
                TextButton(
                  onPressed: onClear,
                  child: Text(s.t('clearFilters')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportOverview extends StatelessWidget {
  const _ReportOverview({required this.vm});
  final MyReportsViewModel vm;
  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    final total = vm.submittedReports.length;
    final rate = vm.resolutionPercentage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.t('filtered'), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800
                ? 5
                : constraints.maxWidth >= 460
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(
                  width: width,
                  label: s.t('total'),
                  value: '$total',
                  color: Theme.of(context).colorScheme.secondary,
                ),
                for (final status in ReportStatus.values)
                  _Metric(
                    width: width,
                    label: s.t(status.labelKey),
                    value: '${vm.count(status)}',
                    color: status.displayColor(context),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t('resolution'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  rate == null ? '—' : '${rate.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.displaySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 12),
                if (rate != null)
                  LinearProgressIndicator(
                    value: rate / 100,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(8),
                    semanticsLabel: s.t('resolution'),
                  ),
                const SizedBox(height: 12),
                Text(
                  rate == null
                      ? s.t('noSubmitted')
                      : '${vm.count(ReportStatus.resolved)} / $total ${s.t('ofSubmitted')}',
                ),
                const SizedBox(height: 12),
                Text(
                  s.t('resolutionFormula'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t('statusBreakdown'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final status in ReportStatus.values) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Text(s.t(status.labelKey))),
                      Text('${vm.count(status)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : vm.count(status) / total,
                    color: status.displayColor(context),
                    backgroundColor: status
                        .displayColor(context)
                        .withValues(alpha: .10),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    semanticsLabel:
                        '${s.t(status.labelKey)}: ${vm.count(status)} / $total',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
  });
  final double width;
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    ),
  );
}

class _RefreshReports extends StatelessWidget {
  const _RefreshReports({required this.vm, required this.child});
  final MyReportsViewModel vm;
  final Widget child;
  @override
  Widget build(BuildContext context) => vm.loadReports == null
      ? child
      : RefreshIndicator(onRefresh: vm.refresh, child: child);
}
