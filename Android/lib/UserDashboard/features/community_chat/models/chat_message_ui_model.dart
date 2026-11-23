enum MessageDelivery { demoLocal, delivered }

enum ChatSenderRole { student, departmentAdmin }

class ChatMessageUiModel {
  const ChatMessageUiModel({
    required this.id,
    required this.senderId,
    required this.senderAlias,
    required this.text,
    required this.sentAt,
    this.delivery = MessageDelivery.demoLocal,
    this.role = ChatSenderRole.student,
  });
  final String id;
  final String senderId;
  final String senderAlias;
  final String text;
  final DateTime sentAt;
  final MessageDelivery delivery;

  /// Display metadata supplied by the host; this does not grant privileges.
  final ChatSenderRole role;
}
