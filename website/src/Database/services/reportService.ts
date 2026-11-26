import type { RealtimePostgresChangesPayload } from '@supabase/supabase-js';
import { getSupabaseClient } from '../client';
import { throwMappedDatabaseError } from '../errors';
import type {
  AdminDashboardStats,
  IncidentReport,
  PaginatedResult,
  ReportStatus,
  ReportUpdate,
} from '../types';

const ATTACHMENTS_BUCKET = 'report-attachments';

function mapUpdate(row: Record<string, unknown>): ReportUpdate {
  return {
    id: String(row.id),
    reportId: String(row.report_id),
    actorId: row.actor_id ? String(row.actor_id) : null,
    status: row.status as ReportStatus,
    note: String(row.note),
    createdAt: String(row.created_at),
  };
}

function mapReport(row: Record<string, unknown>): IncidentReport {
  const rawUpdates = Array.isArray(row.report_updates)
    ? (row.report_updates as Record<string, unknown>[])
        .map(mapUpdate)
        .sort((a, b) => a.createdAt.localeCompare(b.createdAt))
    : undefined;

  return {
    id: String(row.id),
    reportCode: String(row.report_code),
    reporterId: row.reporter_id ? String(row.reporter_id) : null,
    pinId: row.pin_id ? String(row.pin_id) : null,
    categoryKey: String(row.category_key),
    title: String(row.title),
    location: String(row.location),
    description: String(row.description),
    status: row.status as ReportStatus,
    reporterLat: row.reporter_lat != null ? Number(row.reporter_lat) : null,
    reporterLng: row.reporter_lng != null ? Number(row.reporter_lng) : null,
    isGpsVerified: Boolean(row.is_gps_verified),
    attachmentPaths: Array.isArray(row.attachment_paths)
      ? row.attachment_paths.map(String)
      : [],
    resolvedBy: row.resolved_by ? String(row.resolved_by) : null,
    createdAt: String(row.created_at),
    submittedAt: String(row.submitted_at),
    resolvedAt: row.resolved_at ? String(row.resolved_at) : null,
    updatedAt: String(row.updated_at),
    updates: rawUpdates,
  };
}

export interface GetReportsFilters {
  limit?: number;
  offset?: number;
  status?: ReportStatus;
  categoryKey?: string;
  pinId?: string;
  search?: string;
}

/**
 * Fetches reports ordered newest first (`created_at DESC`) with pagination (default latest 10)
 * and exact `totalCount` + `hasMore`.
 *
 * RLS automatically scopes regular `admin` to their assigned department and grants
 * `super_admin` visibility across all reports.
 */
export async function getReports(
  filters: GetReportsFilters = {},
): Promise<PaginatedResult<IncidentReport>> {
  try {
    const limit = Math.min(Math.max(filters.limit ?? 10, 1), 100);
    const offset = Math.max(filters.offset ?? 0, 0);

    let query = getSupabaseClient()
      .from('reports')
      .select('*, report_updates(*)', { count: 'exact' });

    if (filters.status) {
      query = query.eq('status', filters.status);
    }
    if (filters.categoryKey?.trim()) {
      query = query.eq('category_key', filters.categoryKey.trim());
    }
    if (filters.pinId?.trim()) {
      query = query.eq('pin_id', filters.pinId.trim());
    }
    if (filters.search?.trim()) {
      const term = filters.search.trim();
      query = query.or(`title.ilike.%${term}%,report_code.ilike.%${term}%`);
    }

    const { data, count, error } = await query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    const items = (data ?? []).map((row) => mapReport(row as Record<string, unknown>));
    const totalCount = count ?? items.length;

    return {
      items,
      totalCount,
      hasMore: offset + items.length < totalCount,
      limit,
      offset,
    };
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_reports_failed');
  }
}

/**
 * Fetches full report details including status timeline and short-lived RBAC-verified
 * signed URLs for all attached photos.
 */
export async function getReportDetails(
  reportId: string,
  signedUrlExpirySeconds = 3600,
): Promise<IncidentReport | null> {
  try {
    const supabase = getSupabaseClient();
    const { data, error } = await supabase
      .from('reports')
      .select('*, report_updates(*)')
      .eq('id', reportId)
      .maybeSingle();

    if (error) throw error;
    if (!data) return null;

    const report = mapReport(data as Record<string, unknown>);
    if (report.attachmentPaths.length > 0) {
      const { data: signed, error: signedError } = await supabase.storage
        .from(ATTACHMENTS_BUCKET)
        .createSignedUrls(report.attachmentPaths, signedUrlExpirySeconds);

      if (signedError) throw signedError;
      report.signedAttachmentUrls = (signed ?? [])
        .map((item) => item.signedUrl)
        .filter((url): url is string => Boolean(url));
    } else {
      report.signedAttachmentUrls = [];
    }

    return report;
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_report_details_failed');
  }
}

/**
 * Atomically updates a report's status and appends a timeline note via `update_report_status` RPC.
 * Transitioning to `'resolved'` automatically triggers contribution points (+20 student, +10 admin).
 */
export async function updateReportStatus(
  reportId: string,
  newStatus: ReportStatus,
  note: string,
): Promise<IncidentReport> {
  try {
    const { data, error } = await getSupabaseClient().rpc('update_report_status', {
      p_report_id: reportId,
      p_new_status: newStatus,
      p_note: note.trim(),
    });

    if (error) throw error;
    return mapReport(data as Record<string, unknown>);
  } catch (err) {
    throwMappedDatabaseError(err, 'update_report_status_failed');
  }
}

/**
 * Returns dashboard analytics counts scoped automatically by RLS
 * (department-scoped for regular `admin`, global for `super_admin`).
 */
export async function getDashboardStats(): Promise<AdminDashboardStats> {
  try {
    const { data, error } = await getSupabaseClient().rpc('get_admin_dashboard_stats');
    if (error) throw error;

    const row = (Array.isArray(data) ? data[0] : data) as Record<string, unknown> | undefined;
    return {
      waitingCount: Number(row?.waiting_count ?? 0),
      pendingCount: Number(row?.pending_count ?? 0),
      inProgressCount: Number(row?.in_progress_count ?? 0),
      resolvedCount: Number(row?.resolved_count ?? 0),
      rejectedCount: Number(row?.rejected_count ?? 0),
      totalCount: Number(row?.total_count ?? 0),
    };
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_dashboard_stats_failed');
  }
}

/**
 * Subscribes to live changes on `reports` for real-time Admin Dashboard updates.
 * Returns an unsubscribe cleanup function.
 */
export function subscribeToReports(
  onChange: (payload: RealtimePostgresChangesPayload<Record<string, unknown>>) => void,
): () => void {
  const supabase = getSupabaseClient();
  const channel = supabase
    .channel('admin-reports-live')
    .on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'reports' },
      onChange,
    )
    .subscribe();

  return () => {
    void supabase.removeChannel(channel);
  };
}
