import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../models/chat_message_ui_model.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onReport,
    this.grouped = false,
    this.onBlock,
  });
  final ChatMessageUiModel message;
  final bool isMine;
  final bool grouped;
  final VoidCallback onReport;
  final VoidCallback? onBlock;

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: isMine ? 24 : 0,
          right: isMine ? 0 : 24,
          bottom: grouped ? 8 : 16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: GestureDetector(
            onLongPress: () => _showMessageActions(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMine
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: message.role == ChatSenderRole.departmentAdmin
                      ? scheme.primary
                      : scheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.role == ChatSenderRole.departmentAdmin) ...[
                        Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (!grouped)
                        Flexible(
                          child: Text(
                            isMine ? s.t('you') : message.senderAlias,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SelectableText(
                      message.text,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurface, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(message.sentAt.toLocal()), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}${message.delivery == MessageDelivery.demoLocal ? ' · ${s.t('localOnly')}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    final s = CampusStrings.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(s.t('reportMessage')),
              onTap: () {
                Navigator.pop(sheetContext);
                onReport();
              },
            ),
            if (!isMine && onBlock != null)
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: Text(s.t('blockSender')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onBlock!();
                },
              ),
          ],
        ),
      ),
    );
  }
}
