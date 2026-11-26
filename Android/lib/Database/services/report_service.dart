import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../database_config.dart';
import '../database_exception.dart';
import '../models/database_models.dart';

/// Payload for an image attachment uploaded to the private `report-attachments` bucket.
class ReportAttachmentUpload {
  const ReportAttachmentUpload({
    required this.fileName,
    required this.bytes,
    this.contentType = 'image/jpeg',
  });

  final String fileName;
  final Uint8List bytes;
  final String contentType;
}

/// Mobile incident reporting wrappers (submission, paginated history, signed URLs, Realtime).
class ReportService {
  ReportService({SupabaseClient? client}) : _client = client;

  static const String attachmentsBucket = 'report-attachments';

  final SupabaseClient? _client;
  SupabaseClient get _db => _client ?? DatabaseConfig.client;

  /// Submits a new incident report with optional GPS coordinates and multiple photo attachments.
  ///
  /// `is_gps_verified` is computed server-side against `campus_settings` by a DB trigger.
  Future<IncidentReportModel> submitReport({
    String? pinId,
    required String categoryKey,
    required String title,
    required String location,
    required String description,
    double? reporterLat,
    double? reporterLng,
    List<ReportAttachmentUpload> attachments = const [],
  }) async {
    try {
      final userId = DatabaseConfig.requireCurrentUserId();
      final uploadBatchId = DateTime.now().microsecondsSinceEpoch.toString();
      final uploadedPaths = <String>[];

      for (var i = 0; i < attachments.length; i++) {
        final item = attachments[i];
        final sanitizedName = item.fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final storagePath = '$userId/$uploadBatchId/${i}_$sanitizedName';

        await _db.storage.from(attachmentsBucket).uploadBinary(
          storagePath,
          item.bytes,
          fileOptions: FileOptions(
            contentType: item.contentType,
            upsert: false,
          ),
        );
        uploadedPaths.add(storagePath);
      }

      final inserted = await _db
          .from('reports')
          .insert({
            'reporter_id': userId,
            'pin_id': pinId,
            'category_key': categoryKey,
            'title': title.trim(),
            'location': location.trim(),
            'description': description.trim(),
            'reporter_lat': reporterLat,
            'reporter_lng': reporterLng,
            'attachment_paths': uploadedPaths,
          })
          .select('*, report_updates(*)')
          .single();

      return IncidentReportModel.fromJson(inserted);
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'submit_report_failed');
    }
  }

  /// Fetches the logged-in student's reports ordered newest first (`created_at DESC`)
  /// with pagination (defaults to latest 10) and exact [totalCount] / [hasMore].
  Future<PaginatedResult<IncidentReportModel>> getMyReports({
    int limit = 10,
    int offset = 0,
    DbReportStatus? status,
    String? categoryKey,
    String? search,
  }) async {
    try {
      final userId = DatabaseConfig.requireCurrentUserId();
      final safeLimit = limit.clamp(1, 100);
      final safeOffset = offset < 0 ? 0 : offset;

      var query = _db
          .from('reports')
          .select('*, report_updates(*)')
          .eq('reporter_id', userId);

      if (status != null) {
        query = query.eq('status', status.value);
      }
      if (categoryKey != null && categoryKey.trim().isNotEmpty) {
        query = query.eq('category_key', categoryKey.trim());
      }
      if (search != null && search.trim().isNotEmpty) {
        final term = search.trim();
        query = query.or('title.ilike.%$term%,report_code.ilike.%$term%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(safeOffset, safeOffset + safeLimit - 1)
          .count(CountOption.exact);

      final items = (response.data as List)
          .map((e) => IncidentReportModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final totalCount = response.count;

      return PaginatedResult<IncidentReportModel>(
        items: items,
        totalCount: totalCount,
        hasMore: (safeOffset + items.length) < totalCount,
        limit: safeLimit,
        offset: safeOffset,
      );
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'fetch_my_reports_failed');
    }
  }

  /// Fetches a single report owned by the logged-in student with full timeline updates.
  Future<IncidentReportModel?> getReportById(String reportId) async {
    try {
      final row = await _db
          .from('reports')
          .select('*, report_updates(*)')
          .eq('id', reportId)
          .maybeSingle();

      if (row == null) return null;
      return IncidentReportModel.fromJson(row);
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'fetch_report_failed');
    }
  }

  /// Generates short-lived RBAC-verified signed URLs for private report attachments.
  Future<List<String>> getAttachmentSignedUrls(
    List<String> attachmentPaths, {
    int expiresInSeconds = 3600,
  }) async {
    try {
      if (attachmentPaths.isEmpty) return const [];
      final signed = await _db.storage
          .from(attachmentsBucket)
          .createSignedUrls(attachmentPaths, expiresInSeconds);

      return signed.map((item) => item.signedUrl).toList();
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'signed_url_failed');
    }
  }

  /// Subscribes to real-time changes on the logged-in student's reports.
  /// Call `channel.unsubscribe()` in `dispose()`.
  RealtimeChannel subscribeToMyReports({
    required void Function(PostgresChangePayload payload) onChange,
  }) {
    final userId = DatabaseConfig.requireCurrentUserId();
    return _db
        .channel('my-reports-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reports',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'reporter_id',
            value: userId,
          ),
          callback: onChange,
        )
        .subscribe();
  }
}
