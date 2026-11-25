import '../models/leaderboard_entry_ui_model.dart';

/// Fixed fictional results, not a point-awarding algorithm.
Map<RankingPeriod, List<LeaderboardEntryUiModel>> mockRankings() => {
  RankingPeriod.monthly: const [
    LeaderboardEntryUiModel(
      studentId: 'demo-fern',
      rank: 1,
      alias: 'Campus Fern',
      points: 180,
      verifiedContributions: 8,
    ),
    LeaderboardEntryUiModel(
      studentId: 'demo-river',
      rank: 2,
      alias: 'River Guide',
      points: 165,
      verifiedContributions: 7,
    ),
    LeaderboardEntryUiModel(
      studentId: 'demo-cedar',
      rank: 3,
      alias: 'Kind Cedar',
      points: 140,
      verifiedContributions: 6,
    ),
    LeaderboardEntryUiModel(
      studentId: 'demo-student',
      rank: 4,
      alias: 'Quiet Oak',
      points: 120,
      verifiedContributions: 5,
    ),
    LeaderboardEntryUiModel(
      studentId: 'demo-iris',
      rank: 5,
      alias: 'Blue Iris',
      points: 95,
      verifiedContributions: 4,
    ),
    LeaderboardEntryUiModel(
      studentId: 'demo-pine',
      rank: 6,
      alias: 'Steady Pine',
      points: 80,
      verifiedContributions: 3,
    ),
  ],
  RankingPeriod.allTime: const [
    LeaderboardEntryUiModel(
      studentId: 'demo-cedar',
      rank: 1,
      alias: 'Kind Cedar',
      points: 920,
      verifiedContributions: 40,
    ),
    LeaderboardEntryUiModel(
      studentId: 'demo-fern',
      rank: 2,
      alias: 'Campus Fern',
      points: 860,
      verifiedContributions: 37,
    ),
    LeaderboardEntryUiModel(
      studentId: 'demo-river',
      rank: 3,
      alias: 'River Guide',
      points: 810,
      verifiedContributions: 35,
    ),
    LeaderboardEntryUiModel(
      studentId: 'demo-iris',
      rank: 4,
      alias: 'Blue Iris',
      points: 740,
      verifiedContributions: 32,
    ),
    LeaderboardEntryUiModel(
      studentId: 'demo-pine',
      rank: 5,
      alias: 'Steady Pine',
      points: 650,
      verifiedContributions: 28,
    ),
    LeaderboardEntryUiModel(
      studentId: 'demo-student',
      rank: 6,
      alias: 'Quiet Oak',
      points: 590,
      verifiedContributions: 25,
    ),
  ],
};
