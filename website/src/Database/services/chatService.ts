import { getSupabaseClient } from '../client';
import { DatabaseException, throwMappedDatabaseError } from '../errors';
import type {
  AdminDepartment,
  ChatChannel,
  ChatChannelType,
  ChatMessage,
  ChatMessageFlag,
  MessageFlagStatus,
  UserRole,
} from '../types';

function mapChannel(row: Record<string, unknown>): ChatChannel {
  return {
    id: String(row.id),
    type: row.type as ChatChannelType,
    name: row.name ? String(row.name) : null,
    department: (row.department as AdminDepartment | null) ?? null,
    studentId: row.student_id ? String(row.student_id) : null,
    createdAt: String(row.created_at),
  };
}

function mapMessage(row: Record<string, unknown>): ChatMessage {
  return {
    id: String(row.id),
    channelId: String(row.channel_id),
    senderId: row.sender_id ? String(row.sender_id) : null,
    senderAlias: String(row.sender_alias_snapshot ?? 'Deleted User'),
    senderRole: (row.sender_role_snapshot as UserRole) ?? 'user',
    body: String(row.body),
    sentAt: String(row.sent_at),
  };
}

function mapFlag(row: Record<string, unknown>): ChatMessageFlag {
  return {
    id: String(row.id),
    messageId: String(row.message_id),
    reporterId: row.reporter_id ? String(row.reporter_id) : null,
    reason: String(row.reason),
    status: row.status as MessageFlagStatus,
    createdAt: String(row.created_at),
    message: row.chat_messages
      ? mapMessage(row.chat_messages as Record<string, unknown>)
      : undefined,
  };
}

export async function getCommunityChannel(): Promise<ChatChannel> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('chat_channels')
      .select('*')
      .eq('type', 'community')
      .limit(1)
      .single();

    if (error) throw error;
    return mapChannel(data as Record<string, unknown>);
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_community_chat_failed');
  }
}

/**
 * Lists student <-> department support threads (`user_admin`).
 * - Regular `admin`: RLS automatically returns only threads matching their department.
 * - `super_admin`: RLS grants oversight across all 4 departments; optionally pass `department` to filter.
 */
export async function getDepartmentStudentChats(
  department?: AdminDepartment,
): Promise<ChatChannel[]> {
  try {
    let query = getSupabaseClient()
      .from('chat_channels')
      .select('*')
      .eq('type', 'user_admin');

    if (department) {
      query = query.eq('department', department);
    }

    const { data, error } = await query.order('created_at', { ascending: false });
    if (error) throw error;
    return (data ?? []).map((row) => mapChannel(row as Record<string, unknown>));
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_department_chats_failed');
  }
}

/**
 * Lists Web Portal direct staff channels (`admin_super_admin`) the caller participates in.
 */
export async function getAdminSuperAdminChannels(): Promise<ChatChannel[]> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('chat_channels')
      .select('*')
      .eq('type', 'admin_super_admin')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return (data ?? []).map((row) => mapChannel(row as Record<string, unknown>));
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_staff_channels_failed');
  }
}

/**
 * Opens or creates a private Web Portal channel between an `admin` and `super_admin`.
 */
export async function getOrCreateAdminSuperAdminChannel(
  targetProfileId: string,
): Promise<ChatChannel> {
  try {
    const { data, error } = await getSupabaseClient().rpc(
      'get_or_create_admin_super_admin_channel',
      { p_target_profile_id: targetProfileId },
    );

    if (error) throw error;
    return mapChannel(data as Record<string, unknown>);
  } catch (err) {
    throwMappedDatabaseError(err, 'open_staff_channel_failed');
  }
}

export async function getMessages(channelId: string, limit = 100): Promise<ChatMessage[]> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('chat_messages')
      .select('*')
      .eq('channel_id', channelId)
      .order('sent_at', { ascending: true })
      .limit(Math.min(Math.max(limit, 1), 500));

    if (error) throw error;
    return (data ?? []).map((row) => mapMessage(row as Record<string, unknown>));
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_messages_failed');
  }
}

export async function sendMessage(channelId: string, body: string): Promise<ChatMessage> {
  try {
    const trimmed = body.trim();
    if (!trimmed || trimmed.length > 1000) {
      throw new DatabaseException(
        'invalid_message',
        'Message must be between 1 and 1000 characters.',
      );
    }

    const supabase = getSupabaseClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      throw new DatabaseException('unauthenticated', 'You must be signed in to send messages.');
    }

    const { data, error } = await supabase
      .from('chat_messages')
      .insert({
        channel_id: channelId,
        sender_id: user.id,
        body: trimmed,
      })
      .select()
      .single();

    if (error) throw error;
    return mapMessage(data as Record<string, unknown>);
  } catch (err) {
    throwMappedDatabaseError(err, 'send_message_failed');
  }
}

/**
 * Moderation: Deletes a chat message.
 * RLS enforces:
 * - Regular `admin`: can delete messages inside the `community` channel ONLY.
 * - `super_admin`: can delete messages inside both `community` and `user_admin` channels.
 */
export async function deleteMessage(messageId: string): Promise<void> {
  try {
    const { error } = await getSupabaseClient()
      .from('chat_messages')
      .delete()
      .eq('id', messageId);

    if (error) throw error;
  } catch (err) {
    throwMappedDatabaseError(err, 'delete_message_failed');
  }
}

/**
 * Moderation: Lists flagged chat messages.
 * RLS automatically scopes regular `admin` to `community` flags and grants `super_admin`
 * visibility across both `community` and `user_admin` flags.
 */
export async function getFlaggedMessages(
  status?: MessageFlagStatus,
): Promise<ChatMessageFlag[]> {
  try {
    let query = getSupabaseClient()
      .from('chat_message_reports')
      .select('*, chat_messages(*)')
      .order('created_at', { ascending: false });

    if (status) {
      query = query.eq('status', status);
    }

    const { data, error } = await query;
    if (error) throw error;
    return (data ?? []).map((row) => mapFlag(row as Record<string, unknown>));
  } catch (err) {
    throwMappedDatabaseError(err, 'fetch_flagged_messages_failed');
  }
}

/**
 * Moderation: Updates the review status of a flagged message (`reviewed` or `dismissed`).
 */
export async function updateFlaggedMessageStatus(
  flagId: string,
  status: MessageFlagStatus,
): Promise<ChatMessageFlag> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('chat_message_reports')
      .update({ status })
      .eq('id', flagId)
      .select('*, chat_messages(*)')
      .single();

    if (error) throw error;
    return mapFlag(data as Record<string, unknown>);
  } catch (err) {
    throwMappedDatabaseError(err, 'update_flag_status_failed');
  }
}

export interface ChannelSubscriptionCallbacks {
  onInsert: (message: ChatMessage) => void;
  onDelete?: (deletedMessageId: string) => void;
}

export function subscribeToChannelMessages(
  channelId: string,
  callbacks: ChannelSubscriptionCallbacks,
): () => void {
  const supabase = getSupabaseClient();
  const channel = supabase
    .channel(`web-chat-${channelId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'chat_messages',
        filter: `channel_id=eq.${channelId}`,
      },
      (payload) => {
        if (payload.new && Object.keys(payload.new).length > 0) {
          callbacks.onInsert(mapMessage(payload.new as Record<string, unknown>));
        }
      },
    )
    .on(
      'postgres_changes',
      {
        event: 'DELETE',
        schema: 'public',
        table: 'chat_messages',
        filter: `channel_id=eq.${channelId}`,
      },
      (payload) => {
        const id = (payload.old as Record<string, unknown> | undefined)?.id;
        if (id && callbacks.onDelete) {
          callbacks.onDelete(String(id));
        }
      },
    )
    .subscribe();

  return () => {
    void supabase.removeChannel(channel);
  };
}
