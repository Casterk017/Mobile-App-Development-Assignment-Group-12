import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';

/// Host-supplied, verified contact. Calling/navigation belongs to the host.
class CampusHelpContact {
  const CampusHelpContact({
    required this.name,
    required this.details,
    this.onContact,
  });
  final String name;
  final String details;
  final Future<void> Function()? onContact;
}

Future<void> showSafetyHelp(
  BuildContext context, {
  List<CampusHelpContact> contacts = const [],
}) {
  final s = CampusStrings.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.t('helpTitle')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.t('helpBody')),
            const SizedBox(height: 20),
            if (contacts.isEmpty) Text(s.t('contactsUnavailable')),
            for (final contact in contacts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(contact.name),
                subtitle: Text(contact.details),
                trailing: contact.onContact == null
                    ? null
                    : const Icon(Icons.open_in_new),
                onTap: contact.onContact == null
                    ? null
                    : () async {
                        try {
                          await contact.onContact!();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.t('tryAgain'))),
                            );
                          }
                        }
                      },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.t('close')),
        ),
      ],
    ),
  );
}
