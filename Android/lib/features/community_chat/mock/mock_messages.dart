import '../models/chat_message_ui_model.dart';

List<ChatMessageUiModel> mockMessages() => [
  ChatMessageUiModel(
    id: 'demo-m1',
    senderId: 'demo-fern',
    senderAlias: 'Student 1',
    text: 'A small reminder to keep accessible entrances clear. It makes a difference for everyone.',
    sentAt: DateTime(2026, 11, 22, 9, 10),
  ),
  ChatMessageUiModel(
    id: 'demo-m2',
    senderId: 'demo-admin',
    senderAlias: 'Department Admin',
    role: ChatSenderRole.departmentAdmin,
    text: 'Good reminder! Please use the official report form for maintenance issues rather than sharing personal details here.',
    sentAt: DateTime(2026, 11, 22, 9, 14),
  ),
  ChatMessageUiModel(
    id: 'demo-m3',
    senderId: 'demo-student',
    senderAlias: 'You',
    text: 'Thanks for keeping this space helpful and respectful.',
    sentAt: DateTime(2026, 11, 22, 9, 16),
  ),
];
