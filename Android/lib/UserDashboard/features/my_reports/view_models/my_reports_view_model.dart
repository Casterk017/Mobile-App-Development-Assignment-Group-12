import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;

import '../models/report_ui_model.dart';

enum ReportSort { newest, oldest }

class MyReportsViewModel extends ChangeNotifier {
  MyReportsViewModel({
    required this.currentStudentId,
    required List<ReportUiModel> reports,
    this.loadReports,
    this.lastUpdated,
    this.offline = false,
    bool initialLoading = false,
    bool initialError = false,
  }) : _reports = List.of(reports),
       _loading = initialLoading,
       _hasError = initialError;

  final String currentStudentId;
  final DateTime? lastUpdated;
  final bool offline;
  final Future<List<ReportUiModel>> Function()? loadReports;
  List<ReportUiModel> _reports;
  bool _loading;
  bool _hasError;
  bool _disposed = false;
  ReportStatus? _status;
  String? _category;
  String _query = '';
  String get query => _query;
  bool get hasData => studentReports.isNotEmpty;
  List<ReportUiModel> get studentReports =>
      List.unmodifiable(_reports.where((r) => r.studentId == currentStudentId));
  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  DateTimeRange? _dateRange;
  ReportSort _sort = ReportSort.newest;

  bool get loading => _loading;
  bool get hasError => _hasError;
  ReportStatus? get status => _status;
  String? get category => _category;
  DateTimeRange? get dateRange => _dateRange;
  ReportSort get sort => _sort;
  List<String> get categories =>
      (_reports
          .where((r) => r.studentId == currentStudentId)
          .map((r) => r.categoryKey)
          .toSet()
          .toList()
        ..sort());

  List<ReportUiModel> get visibleReports {
    final result = _reports.where((r) {
      // Defense in depth for the prototype; backend authorization is still required.
      if (r.studentId != currentStudentId) return false;
      if (_query.trim().isNotEmpty &&
          !('${r.id} ${r.title}'.toLowerCase().contains(
            _query.trim().toLowerCase(),
          ))) {
        return false;
      }
      if (_status != null && r.status != _status) return false;
      if (_category != null && r.categoryKey != _category) return false;
      final range = _dateRange;
      if (range != null) {
        final local = r.displayDate.toLocal();
        final day = DateTime(local.year, local.month, local.day);
        if (day.isBefore(range.start) || day.isAfter(range.end)) return false;
      }
      return true;
    }).toList();
    result.sort(
      (a, b) => _sort == ReportSort.newest
          ? b.displayDate.compareTo(a.displayDate)
          : a.displayDate.compareTo(b.displayDate),
    );
    return List.unmodifiable(result);
  }

  List<ReportUiModel> get submittedReports => visibleReports
      .where((r) => r.submissionState == SubmissionState.submitted)
      .toList();
  int count(ReportStatus value) =>
      submittedReports.where((r) => r.status == value).length;
  double? get resolutionPercentage => submittedReports.isEmpty
      ? null
      : count(ReportStatus.resolved) / submittedReports.length * 100;

  void setStatus(ReportStatus? value) {
    _status = value;
    notifyListeners();
  }

  void setCategory(String? value) {
    _category = value;
    notifyListeners();
  }

  void setSort(ReportSort value) {
    _sort = value;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? value) {
    _dateRange = value == null
        ? null
        : DateTimeRange(
            start: DateTime(
              value.start.year,
              value.start.month,
              value.start.day,
            ),
            end: DateTime(value.end.year, value.end.month, value.end.day),
          );
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _status = null;
    _category = null;
    _dateRange = null;
    _sort = ReportSort.newest;
    notifyListeners();
  }

  /// Host-driven replacement; widgets never change incident status themselves.
  void replaceReports(List<ReportUiModel> reports) {
    _reports = List.of(reports);
    _hasError = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (loadReports == null || _loading) return;
    _loading = true;
    _hasError = false;
    notifyListeners();
    try {
      final records = await loadReports!();
      if (!_disposed) _reports = List.of(records);
    } catch (_) {
      if (!_disposed) _hasError = true;
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
