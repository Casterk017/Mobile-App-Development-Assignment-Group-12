import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../app/locale_controller.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key, required this.controller});
  final LocaleController controller;

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(s.t('language'))),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                StudentHeading(
                  eyebrow: s.t('preferences'),
                  title: s.t('languageTitle'),
                  subtitle: s.t('languageSubtitle'),
                ),
                Text(
                  s.t('currentLanguage'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 16),
                for (final language in [
                  ('en', 'English'),
                  ('ms', 'Bahasa Melayu'),
                  ('zh', '简体中文'),
                ]) ...[
                  Semantics(
                    selected: controller.locale.languageCode == language.$1,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        key: ValueKey('language-${language.$1}'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        title: Text(language.$2),
                        subtitle: controller.locale.languageCode == language.$1
                            ? Text(s.t('selected'))
                            : null,
                        trailing: Icon(
                          controller.locale.languageCode == language.$1
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onTap: controller.saving
                            ? null
                            : () async {
                                try {
                                  await controller.select(Locale(language.$1));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          CampusStrings(controller.locale)
                                              .t('languageChanged'),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          CampusStrings.of(context)
                                              .t('languageError'),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (controller.saving) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
