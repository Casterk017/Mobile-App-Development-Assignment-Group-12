/**
 * Shared TypeScript contracts for Website/src/Database/.
 */

export type UserRole = 'user' | 'admin' | 'super_admin';

/** Fixed 4 admin departments supported by the Campus Safety system. */
export type AdminDepartment = 'facilities' | 'cleaner' | 'parking' | 'security';

export type ReportStatus = 'pending' | 'in_progress' | 'resolved' | 'rejected';

export type RankingPeriod = 'monthly' | 'all_time';

export type ChatChannelType = 'community' | 'user_admin' | 'admin_super_admin';

export type MessageFlagStatus = 'open' | 'reviewed' | 'dismissed';

export interface Profile {
  id: string;
  email: string;
  displayName: string;
  publicAlias: string;
  role: UserRole;
  department: AdminDepartment | null;
  createdAt: string;
  updatedAt: string;
}

export interface CampusBounds {
  minLat: number;
  maxLat: number;
  minLng: number;
  maxLng: number;
  updatedBy: string | null;
  updatedAt: string;
}

export interface PresetPin {
  id: string;
  blockName: string;
  sectionTitle: string;
  description: string;
  lat: number;
  lng: number;
  imageUrls: string[];
  createdAt: string;
  updatedAt: string;
}

export interface CategoryMapping {
  categoryKey: string;
  displayLabel: string;
  department: AdminDepartment;
  isActive: boolean;
  createdAt: string;
}

export interface ReportUpdate {
  id: string;
  reportId: string;
  actorId: string | null;
  status: ReportStatus;
  note: string;
  createdAt: string;
}

export interface IncidentReport {
  id: string;
  reportCode: string;
  reporterId: string | null;
  pinId: string | null;
  categoryKey: string;
  title: string;
  location: string;
  description: string;
  status: ReportStatus;
  reporterLat: number | null;
  reporterLng: number | null;
  isGpsVerified: boolean;
  attachmentPaths: string[];
  resolvedBy: string | null;
  createdAt: string;
  submittedAt: string;
  resolvedAt: string | null;
  updatedAt: string;
  updates?: ReportUpdate[];
  signedAttachmentUrls?: string[];
}

export interface PaginatedResult<T> {
  items: T[];
  totalCount: number;
  hasMore: boolean;
  limit: number;
  offset: number;
}

export interface AdminDashboardStats {
  waitingCount: number;
  pendingCount: number;
  inProgressCount: number;
  resolvedCount: number;
  rejectedCount: number;
  totalCount: number;
}

export interface LeaderboardEntry {
  profileId: string;
  rank: number;
  publicAlias: string;
  department: AdminDepartment | null;
  points: number;
  verifiedContributions: number;
}

export interface ChatChannel {
  id: string;
  type: ChatChannelType;
  name: string | null;
  department: AdminDepartment | null;
  studentId: string | null;
  createdAt: string;
}

export interface ChatMessage {
  id: string;
  channelId: string;
  senderId: string | null;
  senderAlias: string;
  senderRole: UserRole;
  body: string;
  sentAt: string;
}

export interface ChatMessageFlag {
  id: string;
  messageId: string;
  reporterId: string | null;
  reason: string;
  status: MessageFlagStatus;
  createdAt: string;
  message?: ChatMessage;
}
