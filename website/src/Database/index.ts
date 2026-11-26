/**
 * Barrel export for Website/src/Database/.
 * Teammates (@JoeyHi, @wongenxi) should import from `../Database`.
 */

export { getSupabaseClient, initDatabase } from './client';
export type { DatabaseInitOptions } from './client';
export { DatabaseException } from './errors';
export * from './types';

export * as authService from './services/authService';
export * as categoryService from './services/categoryService';
export * as pinService from './services/pinService';
export * as reportService from './services/reportService';
export * as accountService from './services/accountService';
export * as leaderboardService from './services/leaderboardService';
export * as chatService from './services/chatService';
