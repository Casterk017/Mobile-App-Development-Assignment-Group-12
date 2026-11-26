import { getSupabaseClient } from '../client';
import { throwMappedDatabaseError } from '../errors';
import type { AdminDepartment, LeaderboardEntry, RankingPeriod } from '../types';

function mapEntry(row: Record<string, unknown>): LeaderboardEntry {
  return {
    profileId: String(row.profile_id),
    rank: Number(row.rank),
    publicAlias: String(row.public_alias),
    department: (row.department as AdminDepartment | null) ?? null,
    points: Number(row.points),
    verifiedContributions: Number(row.verified_contributions),
  };
}

/**
 * Fetches Top N (default 20) student contribution rankings.
 */
export async function getUserRankings(
  period: RankingPeriod = 'monthly',
  limit = 20,
): Promise<LeaderboardEntry[]> {
  try {
    const { data, error } = await getSupabaseClient().rpc('get_leaderboard', {
      p_role: 'user',
      p_period: period,
      p_limit: limit,
    });
    if (error) throw error;
    return (data ?? []).map((row: Record<string, unknown>) => mapEntry(row));
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_user_rankings_failed');
  }
}

/**
 * Super Admin: Fetches Top N (default 20) admin contribution rankings.
 */
export async function getAdminRankings(
  period: RankingPeriod = 'monthly',
  limit = 20,
): Promise<LeaderboardEntry[]> {
  try {
    const { data, error } = await getSupabaseClient().rpc('get_leaderboard', {
      p_role: 'admin',
      p_period: period,
      p_limit: limit,
    });
    if (error) throw error;
    return (data ?? []).map((row: Record<string, unknown>) => mapEntry(row));
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_admin_rankings_failed');
  }
}

/**
 * Fetches the logged-in user's own rank even when outside the Top 20.
 */
export async function getMyRank(
  period: RankingPeriod = 'monthly',
): Promise<LeaderboardEntry | null> {
  try {
    const { data, error } = await getSupabaseClient().rpc('get_my_rank', {
      p_period: period,
    });
    if (error) throw error;
    const rows = Array.isArray(data) ? data : [];
    return rows.length > 0 ? mapEntry(rows[0] as Record<string, unknown>) : null;
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_my_rank_failed');
  }
}
