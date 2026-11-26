import 'package:supabase_flutter/supabase_flutter.dart';

import '../database_config.dart';
import '../database_exception.dart';
import '../models/database_models.dart';

/// Read wrappers for campus preset pins, privacy-safe pin report summaries,
/// and dynamic campus GPS bounds (`campus_settings`).
class PinService {
  PinService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _db => _client ?? DatabaseConfig.client;

  /// Fetches all campus preset pins ordered by block name.
  Future<List<PresetPinRecord>> getPresetPins() async {
    try {
      final rows = await _db
          .from('preset_pins')
          .select()
          .order('block_name', ascending: true);

      return (rows as List)
          .map((e) => PresetPinRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'fetch_pins_failed');
    }
  }

  /// Fetches privacy-safe report summaries for map pins (no reporter PII).
  /// Pass [pinId] to filter to a single pin, or omit to fetch all active pin summaries.
  Future<List<PinReportSummaryRecord>> getPinReportSummaries({
    String? pinId,
  }) async {
    try {
      final rows = await _db.rpc(
        'get_pin_report_summaries',
        params: {'p_pin_id': pinId},
      );

      return (rows as List)
          .map((e) => PinReportSummaryRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'fetch_pin_summaries_failed');
    }
  }

  /// Fetches the current UTS campus GPS bounding box configured by Super Admin.
  Future<CampusBoundsModel> getCampusBounds() async {
    try {
      final row = await _db
          .from('campus_settings')
          .select()
          .eq('id', 'default')
          .single();

      return CampusBoundsModel.fromJson(row);
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'fetch_campus_bounds_failed');
    }
  }
}
