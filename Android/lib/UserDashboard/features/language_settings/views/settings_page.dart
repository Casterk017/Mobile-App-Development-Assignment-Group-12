import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme_controller.dart';
import 'language_settings_page.dart';
import '../../dashboard/views/safety_help.dart';

class StudentSettingsPage extends StatefulWidget {
  const StudentSettingsPage({
    super.key,
    required this.username,
    required this.localeController,
    this.themeController,
    this.helpContacts = const [],
    this.onSignOut,
    this.onNameChanged,
  });
  final String username;
  final ThemeController? themeController;
  final List<CampusHelpContact> helpContacts;
  final LocaleController localeController;
  final Future<void> Function()? onSignOut;
  final Future<void> Function(String name)? onNameChanged;
  @override
  State<StudentSettingsPage> createState() => _StudentSettingsPageState();
}

class _StudentSettingsPageState extends State<StudentSettingsPage> {
  bool _signingOut = false;
  late String _displayName;

  @override
  void initState() {
    super.initState();
    _displayName = widget.username;
  }

  @override
  void didUpdateWidget(covariant StudentSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) _displayName = widget.username;
  }

  Future<void> _editName() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(
        initialName: _displayName,
        onSave: widget.onNameChanged,
      ),
    );
    if (!mounted || name == null) return;
    setState(() => _displayName = name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(CampusStrings.of(context).t('nameUpdated'))),
    );
  }

  Future<void> _signOut() async {
    final s = CampusStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('signOutTitle')),
        content: Text(s.t('signOutBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.t('signOut')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (widget.onSignOut == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.t('signOutUnavailable'))));
      return;
    }
    setState(() => _signingOut = true);
    try {
      await widget.onSignOut!();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(CampusStrings.of(context).t('signOutError'))),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings'))),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .onSurface,
                          child: Icon(Icons.person_outline),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          key: const ValueKey('edit-display-name'),
                          label: Text(s.t('editName')),
                          onPressed: _signingOut ? null : _editName,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      s.t('userName'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _displayName,
                      key: const ValueKey('settings-user-name'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                s.t('preferences'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: widget.localeController,
                builder: (context, _) => Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    key: const ValueKey('language-settings'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: const Icon(Icons.translate_outlined),
                    title: Text(s.t('language')),
                    subtitle: Text(
                      switch (widget.localeController.locale.languageCode) {
                        'ms' => 'Bahasa Melayu',
                        'zh' => '简体中文',
                        _ => 'English',
                      },
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LanguageSettingsPage(
                          controller: widget.localeController,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.themeController case final appearance?)
                ListenableBuilder(
                  listenable: appearance,
                  builder: (context, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.t('appearance'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          RadioGroup<ThemeMode>(
                            groupValue: appearance.mode,
                            onChanged: (value) async {
                              if (value == null || appearance.saving) return;
                              try {
                                await appearance.select(value);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(s.t('preferenceError')),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Column(
                              children: [
                                for (final mode in ThemeMode.values)
                                  RadioListTile<ThemeMode>(
                                    key: ValueKey('theme-${mode.name}'),
                                    enabled: !appearance.saving,
                                    value: mode,
                                    title: Text(
                                      s.t(switch (mode) {
                                        ThemeMode.system => 'themeSystem',
                                        ThemeMode.light => 'themeLight',
                                        ThemeMode.dark => 'themeDark',
                                      }),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.health_and_safety_outlined),
                      title: Text(s.t('getHelp')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showSafetyHelp(
                        context,
                        contacts: widget.helpContacts,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(s.t('privacy')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(s.t('privacy')),
                          content: SingleChildScrollView(
                            child: Text(s.t('privacyBody')),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(s.t('close')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: const ValueKey('settings-sign-out'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: Icon(
                    Icons.logout_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    _signingOut ? s.t('signingOut') : s.t('signOut'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: _signingOut ? null : _signOut,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initialName, this.onSave});
  final String initialName;
  final Future<void> Function(String name)? onSave;
  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final name = _name.text.trim();
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onSave?.call(name);
      if (mounted) Navigator.of(context).pop(name);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(s.t('editName')),
        content: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: const ValueKey('display-name-input'),
                  controller: _name,
                  enabled: !_saving,
                  autofocus: true,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(labelText: s.t('userName')),
                  onFieldSubmitted: (_) => _save(),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return s.t('nameRequired');
                    if (name.characters.length > 60 ||
                        RegExp(r'[\x00-\x1F\x7F]').hasMatch(name)) {
                      return s.t('nameInvalid');
                    }
                    return null;
                  },
                ),
                if (_failed)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      s.t('nameSaveError'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            key: const ValueKey('save-display-name'),
            onPressed: _saving ? null : _save,
            child: Text(s.t(_saving ? 'saving' : 'save')),
          ),
        ],
      ),
    );
  }
}
