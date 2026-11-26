import { getSupabaseClient } from '../client';
import { DatabaseException, throwMappedDatabaseError } from '../errors';
import type { AdminDepartment, CategoryMapping } from '../types';

function mapCategory(row: Record<string, unknown>): CategoryMapping {
  return {
    categoryKey: String(row.category_key),
    displayLabel: String(row.display_label),
    department: row.department as AdminDepartment,
    isActive: Boolean(row.is_active),
    createdAt: String(row.created_at),
  };
}

/**
 * Loads all category -> department mappings (including inactive rows for Super Admin).
 */
export async function getAllCategoryMappings(): Promise<CategoryMapping[]> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('category_department_map')
      .select('*')
      .order('display_label', { ascending: true });

    if (error) throw error;
    return (data ?? []).map((row) => mapCategory(row as Record<string, unknown>));
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_categories_failed');
  }
}

export async function getActiveCategoryMappings(): Promise<CategoryMapping[]> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('category_department_map')
      .select('*')
      .eq('is_active', true)
      .order('display_label', { ascending: true });

    if (error) throw error;
    return (data ?? []).map((row) => mapCategory(row as Record<string, unknown>));
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_active_categories_failed');
  }
}

/**
 * Super Admin: Creates a new dynamic report category mapped to one of the 4 fixed departments.
 */
export async function createCategoryMapping(
  categoryKey: string,
  displayLabel: string,
  department: AdminDepartment,
): Promise<CategoryMapping> {
  try {
    const normalizedKey = categoryKey.trim().toLowerCase().replace(/\s+/g, '_');
    const trimmedLabel = displayLabel.trim();

    if (!/^[a-z0-9_]+$/.test(normalizedKey)) {
      throw new DatabaseException(
        'invalid_category_key',
        'Category key must contain only lowercase letters, numbers, and underscores.',
      );
    }
    if (!trimmedLabel || trimmedLabel.length > 80) {
      throw new DatabaseException(
        'invalid_display_label',
        'Display label must be between 1 and 80 characters.',
      );
    }

    const { data, error } = await getSupabaseClient()
      .from('category_department_map')
      .insert({
        category_key: normalizedKey,
        display_label: trimmedLabel,
        department,
        is_active: true,
      })
      .select()
      .single();

    if (error) throw error;
    return mapCategory(data as Record<string, unknown>);
  } catch (err) {
    throwMappedDatabaseError(err, 'create_category_failed');
  }
}

/**
 * Super Admin: Reassigns a category to a different admin department.
 */
export async function updateCategoryDepartment(
  categoryKey: string,
  department: AdminDepartment,
): Promise<CategoryMapping> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('category_department_map')
      .update({ department })
      .eq('category_key', categoryKey.trim())
      .select()
      .single();

    if (error) throw error;
    return mapCategory(data as Record<string, unknown>);
  } catch (err) {
    throwMappedDatabaseError(err, 'update_category_department_failed');
  }
}

/**
 * Super Admin: Enables or disables a category in the mobile report form dropdown
 * without breaking historical reports referencing that category.
 */
export async function toggleCategoryActive(
  categoryKey: string,
  isActive: boolean,
): Promise<CategoryMapping> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('category_department_map')
      .update({ is_active: isActive })
      .eq('category_key', categoryKey.trim())
      .select()
      .single();

    if (error) throw error;
    return mapCategory(data as Record<string, unknown>);
  } catch (err) {
    throwMappedDatabaseError(err, 'toggle_category_active_failed');
  }
}
