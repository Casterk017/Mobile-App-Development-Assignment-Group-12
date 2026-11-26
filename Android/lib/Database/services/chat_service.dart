import 'package:supabase_flutter/supabase_flutter.dart';

import '../database_config.dart';
import '../database_exception.dart';
import '../models/database_models.dart';

/// Mobile chat wrappers supporting strictly 2 options for students:
/// 1. **Community** (`getCommunityChannel`) — shared campus-wide safety circle.
/// 2. **Admin** (`getOrCreateDepartmentChat`) — student picks 1 of the 4 departments
///    (`facilities`, `cleaner`, `parking`, `security`), excluding `super_admin`.
class ChatService {
  ChatService({SupabaseClient? client}) : _client = client;

  static const String communityChannelId =
      '00000000-0000-0000-0000-000000000001';

  final SupabaseClient? _client;
  SupabaseClient get _db => _client ?? DatabaseConfig.client;

  /// Returns the shared Campus Safety Circle community channel.
  Future<ChatChannelModel> getCommunityChannel() async {
    try {
      final row = await _db
          .from('chat_channels')
          .select()
          .eq('type', 'community')
          .limit(1)
          .single();

      return ChatChannelModel.fromJson(row);
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'fetch_community_chat_failed');
    }
  }

  /// Opens (or creates) the logged-in student's department support thread.
  ///
  /// Uses the `get_or_create_department_chat` SECURITY DEFINER RPC so students
  /// pick one of the 4 fixed departments without querying `profiles`.
  Future<ChatChannelModel> getOrCreateDepartmentChat(
    AdminDepartment department,
  ) async {
    try {
      final row = await _db.rpc(
        'get_or_create_department_chat',
        params: {'p_department': department.value},
      );

      return ChatChannelModel.fromJson(row as Map<String, dynamic>);
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'open_department_chat_failed');
    }
  }

  /// Lists all existing department support threads owned by the logged-in student.
  Future<List<ChatChannelModel>> getMyDepartmentChats() async {
    try {
      final userId = DatabaseConfig.requireCurrentUserId();
      final rows = await _db
          .from('chat_channels')
          .select()
          .eq('type', 'user_admin')
          .eq('student_id', userId)
          .order('created_at', ascending: false);

      return (rows as List)
          .map((e) => ChatChannelModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'fetch_department_chats_failed');
    }
  }

  /// Loads messages in [channelId] ordered oldest-to-newest (blocked senders are
  /// automatically filtered out by PostgreSQL RLS).
  Future<List<ChatMessageRecord>> getMessages(
    String channelId, {
    int limit = 100,
  }) async {
    try {
      final rows = await _db
          .from('chat_messages')
          .select()
          .eq('channel_id', channelId)
          .order('sent_at', ascending: true)
          .limit(limit.clamp(1, 500));

      return (rows as List)
          .map((e) => ChatMessageRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'fetch_messages_failed');
    }
  }

  /// Sends a text message to [channelId] and returns the server-confirmed record.
  Future<ChatMessageRecord> sendMessage({
    required String channelId,
    required String body,
  }) async {
    try {
      final userId = DatabaseConfig.requireCurrentUserId();
      final trimmed = body.trim();
      if (trimmed.isEmpty || trimmed.length > 1000) {
        throw const DatabaseException(
          code: 'invalid_message',
          message: 'Message must be between 1 and 1000 characters.',
        );
      }

      final inserted = await _db
          .from('chat_messages')
          .insert({
            'channel_id': channelId,
            'sender_id': userId,
            'body': trimmed,
          })
          .select()
          .single();

      return ChatMessageRecord.fromJson(inserted);
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'send_message_failed');
    }
  }

  /// Flags a chat message for moderation review.
  Future<void> reportMessage({
    required String messageId,
    String reason = 'inappropriate',
  }) async {
    try {
      final userId = DatabaseConfig.requireCurrentUserId();
      await _db.from('chat_message_reports').insert({
        'message_id': messageId,
        'reporter_id': userId,
        'reason': reason.trim().isEmpty ? 'inappropriate' : reason.trim(),
      });
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'report_message_failed');
    }
  }

  /// Blocks [senderId] so their messages are hidden from the logged-in user via RLS.
  Future<void> blockSender(String senderId) async {
    try {
      final userId = DatabaseConfig.requireCurrentUserId();
      await _db.from('chat_blocked_users').upsert({
        'blocker_id': userId,
        'blocked_id': senderId,
      });
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'block_sender_failed');
    }
  }

  /// Removes a previously blocked sender.
  Future<void> unblockSender(String senderId) async {
    try {
      final userId = DatabaseConfig.requireCurrentUserId();
      await _db
          .from('chat_blocked_users')
          .delete()
          .eq('blocker_id', userId)
          .eq('blocked_id', senderId);
    } catch (e) {
      throwMappedDatabaseError(e, fallbackCode: 'unblock_sender_failed');
    }
  }

  /// Subscribes to live inserts/deletes in [channelId].
  /// Call `channel.unsubscribe()` in `dispose()`.
  RealtimeChannel subscribeToChannelMessages({
    required String channelId,
    required void Function(ChatMessageRecord message) onInsert,
    void Function(String deletedMessageId)? onDelete,
  }) {
    final channel = _db.channel('chat-$channelId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'channel_id',
        value: channelId,
      ),
      callback: (payload) {
        if (payload.newRecord.isNotEmpty) {
          onInsert(ChatMessageRecord.fromJson(payload.newRecord));
        }
      },
    );

    if (onDelete != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'chat_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'channel_id',
          value: channelId,
        ),
        callback: (payload) {
          final id = payload.oldRecord['id'] as String?;
          if (id != null) onDelete(id);
        },
      );
    }

    return channel.subscribe();
  }
}
