import { getSupabaseClient } from '../client';
import { DatabaseException, throwMappedDatabaseError } from '../errors';
import type { CampusBounds, PresetPin } from '../types';

const PIN_IMAGES_BUCKET = 'pin-images';

function mapPin(row: Record<string, unknown>): PresetPin {
  return {
    id: String(row.id),
    blockName: String(row.block_name),
    sectionTitle: String(row.section_title),
    description: String(row.description),
    lat: Number(row.lat),
    lng: Number(row.lng),
    imageUrls: Array.isArray(row.image_urls) ? row.image_urls.map(String) : [],
    createdAt: String(row.created_at),
    updatedAt: String(row.updated_at),
  };
}

function mapBounds(row: Record<string, unknown>): CampusBounds {
  return {
    minLat: Number(row.min_lat),
    maxLat: Number(row.max_lat),
    minLng: Number(row.min_lng),
    maxLng: Number(row.max_lng),
    updatedBy: row.updated_by ? String(row.updated_by) : null,
    updatedAt: String(row.updated_at),
  };
}

export interface CreatePresetPinInput {
  id: string;
  blockName: string;
  sectionTitle: string;
  description: string;
  lat: number;
  lng: number;
  imageUrls?: string[];
}

export interface UpdatePresetPinInput {
  blockName?: string;
  sectionTitle?: string;
  description?: string;
  lat?: number;
  lng?: number;
  imageUrls?: string[];
}

export interface UpdateCampusBoundsInput {
  minLat: number;
  maxLat: number;
  minLng: number;
  maxLng: number;
}

export async function getPresetPins(): Promise<PresetPin[]> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('preset_pins')
      .select('*')
      .order('block_name', { ascending: true });

    if (error) throw error;
    return (data ?? []).map((row) => mapPin(row as Record<string, unknown>));
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_pins_failed');
  }
}

/**
 * Super Admin: Creates a new campus map preset pin.
 */
export async function createPresetPin(input: CreatePresetPinInput): Promise<PresetPin> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('preset_pins')
      .insert({
        id: input.id.trim(),
        block_name: input.blockName.trim(),
        section_title: input.sectionTitle.trim(),
        description: input.description.trim(),
        lat: input.lat,
        lng: input.lng,
        image_urls: input.imageUrls ?? [],
      })
      .select()
      .single();

    if (error) throw error;
    return mapPin(data as Record<string, unknown>);
  } catch (err) {
    throwMappedDatabaseError(err, 'create_pin_failed');
  }
}

/**
 * Super Admin: Updates an existing campus map preset pin.
 */
export async function updatePresetPin(
  pinId: string,
  input: UpdatePresetPinInput,
): Promise<PresetPin> {
  try {
    const patch: Record<string, unknown> = {};
    if (input.blockName !== undefined) patch.block_name = input.blockName.trim();
    if (input.sectionTitle !== undefined) patch.section_title = input.sectionTitle.trim();
    if (input.description !== undefined) patch.description = input.description.trim();
    if (input.lat !== undefined) patch.lat = input.lat;
    if (input.lng !== undefined) patch.lng = input.lng;
    if (input.imageUrls !== undefined) patch.image_urls = input.imageUrls;

    const { data, error } = await getSupabaseClient()
      .from('preset_pins')
      .update(patch)
      .eq('id', pinId.trim())
      .select()
      .single();

    if (error) throw error;
    return mapPin(data as Record<string, unknown>);
  } catch (err) {
    throwMappedDatabaseError(err, 'update_pin_failed');
  }
}

/**
 * Super Admin: Deletes an obsolete preset pin.
 * Historical reports remain intact because `reports.pin_id` uses `ON DELETE SET NULL`
 * while preserving `reports.location`.
 */
export async function deletePresetPin(pinId: string): Promise<void> {
  try {
    const { error } = await getSupabaseClient()
      .from('preset_pins')
      .delete()
      .eq('id', pinId.trim());

    if (error) throw error;
  } catch (err) {
    throwMappedDatabaseError(err, 'delete_pin_failed');
  }
}

/**
 * Super Admin: Uploads a pin photo to the public `pin-images` bucket and returns its public URL.
 */
export async function uploadPinImage(file: File, pinId?: string): Promise<string> {
  try {
    const supabase = getSupabaseClient();
    const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
    const prefix = pinId ? pinId.trim().replace(/[^a-zA-Z0-9_-]/g, '_') : 'general';
    const path = `${prefix}/${Date.now()}_${safeName}`;

    const { error: uploadError } = await supabase.storage
      .from(PIN_IMAGES_BUCKET)
      .upload(path, file, {
        contentType: file.type || 'image/jpeg',
        upsert: false,
      });

    if (uploadError) throw uploadError;

    const { data } = supabase.storage.from(PIN_IMAGES_BUCKET).getPublicUrl(path);
    return data.publicUrl;
  } catch (err) {
    throwMappedDatabaseError(err, 'upload_pin_image_failed');
  }
}

/**
 * Loads the current UTS campus GPS bounds from `campus_settings`.
 */
export async function getCampusBounds(): Promise<CampusBounds> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('campus_settings')
      .select('*')
      .eq('id', 'default')
      .single();

    if (error) throw error;
    return mapBounds(data as Record<string, unknown>);
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_campus_bounds_failed');
  }
}

/**
 * Super Admin: Expands or adjusts the UTS campus GPS bounding box used by
 * server-side `trg_reports_before_insert` GPS verification.
 */
export async function updateCampusBounds(
  bounds: UpdateCampusBoundsInput,
): Promise<CampusBounds> {
  try {
    if (bounds.minLat >= bounds.maxLat || bounds.minLng >= bounds.maxLng) {
      throw new DatabaseException(
        'invalid_bounds',
        'minLat must be less than maxLat and minLng must be less than maxLng.',
      );
    }

    const { data, error } = await getSupabaseClient()
      .from('campus_settings')
      .update({
        min_lat: bounds.minLat,
        max_lat: bounds.maxLat,
        min_lng: bounds.minLng,
        max_lng: bounds.maxLng,
      })
      .eq('id', 'default')
      .select()
      .single();

    if (error) throw error;
    return mapBounds(data as Record<string, unknown>);
  } catch (err) {
    throwMappedDatabaseError(err, 'update_campus_bounds_failed');
  }
}
