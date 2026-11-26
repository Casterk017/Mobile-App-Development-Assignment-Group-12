import 'package:supabase_flutter/supabase_flutter.dart';

import '../database_config.dart';
import '../database_exception.dart';
import '../models/database_models.dart';

/// Dynamic report category wrapper (`category_department_map`).
class CategoryService {
  CategoryService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _db => _client ?? DatabaseConfig.client;

  /// Loads all active report categories so the mobile report form dropdown
  /// reflects Super Admin changes dynamically without app updates.
  Future<List<CategoryMappingModel>> getActiveReportCategories() async {
    try {
      final rows = await _db
          .from('category_department_map')
          .select()
          .eq('is_active', true)
          .order('display_label', ascending: true);

      return (rows as List)
          .map((e) => CategoryMappingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'fetch_categories_failed');
    }
  }
}
