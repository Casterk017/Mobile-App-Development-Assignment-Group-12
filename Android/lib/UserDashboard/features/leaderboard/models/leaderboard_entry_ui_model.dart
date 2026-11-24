/// Ranks and points are supplied by the scoring owner, never awarded by the UI.
class LeaderboardEntryUiModel {
  const LeaderboardEntryUiModel({
    required this.studentId,
    required this.rank,
    required this.alias,
    required this.points,
    required this.verifiedContributions,
  }) : assert(rank > 0),
       assert(points >= 0),
       assert(verifiedContributions >= 0);
  final String studentId;
  final int rank;
  final String alias;
  final int points;
  final int verifiedContributions;
}

enum RankingPeriod { monthly, allTime }
