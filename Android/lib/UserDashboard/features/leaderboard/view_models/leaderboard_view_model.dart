import 'package:flutter/foundation.dart';

import '../models/leaderboard_entry_ui_model.dart';

class LeaderboardViewModel extends ChangeNotifier {
  LeaderboardViewModel({
    required this.currentStudentId,
    required Map<RankingPeriod, List<LeaderboardEntryUiModel>> rankings,
    Map<RankingPeriod, LeaderboardEntryUiModel> currentStudentEntries =
        const {},
    this.loadRankings,
    this.month,
    this.lastUpdated,
    this.offline = false,
    bool initialLoading = false,
    bool initialError = false,
  }) : _rankings = {
         for (final entry in rankings.entries) entry.key: List.of(entry.value),
       },
       _currentStudentEntries = Map.of(currentStudentEntries),
       _loading = initialLoading,
       _hasError = initialError;

  final String currentStudentId;
  final DateTime? month;
  final DateTime? lastUpdated;
  final bool offline;
  bool get hasData => _rankings.values.any((entries) => entries.isNotEmpty);
  final Future<Map<RankingPeriod, List<LeaderboardEntryUiModel>>> Function()?
  loadRankings;
  Map<RankingPeriod, List<LeaderboardEntryUiModel>> _rankings;
  final Map<RankingPeriod, LeaderboardEntryUiModel> _currentStudentEntries;
  RankingPeriod _period = RankingPeriod.monthly;
  bool _loading;
  bool _hasError;
  bool _disposed = false;
  RankingPeriod get period => _period;
  bool get loading => _loading;
  bool get hasError => _hasError;
  List<LeaderboardEntryUiModel> get entries => List.unmodifiable(
    List<LeaderboardEntryUiModel>.of(_rankings[_period] ?? [])
      ..sort((a, b) => a.rank.compareTo(b.rank)),
  );
  LeaderboardEntryUiModel? get currentStudent {
    for (final entry in entries) {
      if (entry.studentId == currentStudentId) return entry;
    }
    final supplied = _currentStudentEntries[_period];
    return supplied?.studentId == currentStudentId ? supplied : null;
  }

  void setPeriod(RankingPeriod value) {
    _period = value;
    notifyListeners();
  }

  void replaceRankings(
    Map<RankingPeriod, List<LeaderboardEntryUiModel>> rankings,
  ) {
    _rankings = {
      for (final entry in rankings.entries) entry.key: List.of(entry.value),
    };
    _hasError = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (loadRankings == null || _loading) return;
    _loading = true;
    _hasError = false;
    notifyListeners();
    try {
      final results = await loadRankings!();
      if (!_disposed) {
        _rankings = {
          for (final entry in results.entries) entry.key: List.of(entry.value),
        };
      }
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
