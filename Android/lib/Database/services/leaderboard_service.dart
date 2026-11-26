import 'package:supabase_flutter/supabase_flutter.dart';

import '../database_config.dart';
import '../database_exception.dart';
import '../models/database_models.dart';

/// Student contribution leaderboard wrappers (Top 20 + logged-in user's own rank).
class LeaderboardService {
  LeaderboardService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _db => _client ?? DatabaseConfig.client;

  /// Fetches the Top [limit] (default `20`) student contributors for [period].
  Future<List<LeaderboardRecord>> getStudentLeaderboard(
    DbRankingPeriod period, {
    int limit = 20,
  }) async {
    try {
      final rows = await _db.rpc(
        'get_leaderboard',
        params: {
          'p_role': 'user',
          'p_period': period.value,
          'p_limit': limit,
        },
      );

      return (rows as List)
          .map((e) => LeaderboardRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'fetch_leaderboard_failed');
    }
  }

  /// Fetches the logged-in student's own rank, points, and verified contributions
  /// for [period], even when outside the Top 20.
  ///
  /// Returns `null` if the student has no verified contributions in [period].
  Future<LeaderboardRecord?> getMyStudentRank(DbRankingPeriod period) async {
    try {
      final rows = await _db.rpc(
        'get_my_rank',
        params: {'p_period': period.value},
      );

      final list = rows as List;
      if (list.isEmpty) return null;
      return LeaderboardRecord.fromJson(list.first as Map<String, dynamic>);
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'fetch_my_rank_failed');
    }
  }
}
