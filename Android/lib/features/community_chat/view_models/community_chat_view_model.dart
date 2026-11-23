import 'package:flutter/foundation.dart';

import '../models/chat_message_ui_model.dart';

/// With no send callback, messages exist in memory only.
/// A connected callback must return the service-confirmed message.
class CommunityChatViewModel extends ChangeNotifier {
  CommunityChatViewModel({
    required this.currentStudentId,
    required this.currentAlias,
    required List<ChatMessageUiModel> messages,
    this.sendMessage,
    this.loadMessages,
    this.reportMessage,
    this.blockSender,
    bool initialLoading = false,
    bool initialError = false,
  }) : _messages = List.of(messages),
       _loading = initialLoading,
       _hasError = initialError;

  final String currentStudentId;
  final Future<void> Function(String senderId)? blockSender;
  final String currentAlias;
  final Future<ChatMessageUiModel> Function(String text)? sendMessage;
  final Future<List<ChatMessageUiModel>> Function()? loadMessages;
  final Future<void> Function(ChatMessageUiModel message)? reportMessage;
  List<ChatMessageUiModel> _messages;
  bool _loading;
  bool _hasError;
  bool _sending = false;
  bool _disposed = false;
  int _localSequence = 0;

  bool get demoMode => sendMessage == null;
  bool get loading => _loading;
  bool get hasError => _hasError;
  bool get sending => _sending;
  List<ChatMessageUiModel> get messages {
    final sorted = List.of(_messages)
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return List.unmodifiable(sorted);
  }

  Future<bool> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 1000 || _sending) return false;
    _sending = true;
    notifyListeners();
    try {
      final message = sendMessage == null
          ? ChatMessageUiModel(
              id: 'local-${DateTime.now().microsecondsSinceEpoch}-${_localSequence++}',
              senderId: currentStudentId,
              senderAlias: currentAlias,
              text: trimmed,
              sentAt: DateTime.now(),
            )
          : await sendMessage!(trimmed);
      if (!_disposed) _messages.add(message);
      return true;
    } catch (_) {
      return false;
    } finally {
      if (!_disposed) {
        _sending = false;
        notifyListeners();
      }
    }
  }

  void replaceMessages(List<ChatMessageUiModel> messages) {
    _messages = List.of(messages);
    _hasError = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (loadMessages == null || _loading) return;
    _loading = true;
    _hasError = false;
    notifyListeners();
    try {
      final messages = await loadMessages!();
      if (!_disposed) _messages = List.of(messages);
    } catch (_) {
      if (!_disposed) _hasError = true;
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
