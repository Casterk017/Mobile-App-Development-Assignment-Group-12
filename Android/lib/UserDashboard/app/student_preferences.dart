import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentPreferenceSnapshot {
  const StudentPreferenceSnapshot({
    this.displayName,
    this.locale = const Locale('en'),
    this.themeMode = ThemeMode.system,
  });
  final String? displayName;
  final Locale locale;
  final ThemeMode themeMode;
}

/// Non-sensitive UI preferences only. Names are scoped to the signed-in student;
/// locale and appearance follow this installation. Never store tokens here.
class StudentPreferences {
  StudentPreferences({
    required this.studentId,
    required this.readString,
    required this.writeString,
  });
  factory StudentPreferences.device({required String studentId}) {
    final preferences = SharedPreferencesAsync();
    return StudentPreferences(
      studentId: studentId,
      readString: preferences.getString,
      writeString: preferences.setString,
    );
  }
  final String studentId;
  final Future<String?> Function(String key) readString;
  final Future<void> Function(String key, String value) writeString;
  String get _nameKey => 'campussafe.student.$studentId.displayName';
  static const _languageKey = 'campussafe.ui.language';
  static const _themeKey = 'campussafe.ui.theme';

  Future<StudentPreferenceSnapshot> load() async {
    final values = await Future.wait([
      readString(_nameKey),
      readString(_languageKey),
      readString(_themeKey),
    ]);
    final name = values[0]?.trim();
    final validName =
        name != null &&
        name.isNotEmpty &&
        name.characters.length <= 60 &&
        !RegExp(r'[\x00-\x1F\x7F]').hasMatch(name);
    return StudentPreferenceSnapshot(
      displayName: validName ? name : null,
      locale: Locale(
        ['en', 'ms', 'zh'].contains(values[1]) ? values[1]! : 'en',
      ),
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == values[2],
        orElse: () => ThemeMode.system,
      ),
    );
  }

  Future<void> saveName(String name) => writeString(_nameKey, name);
  Future<void> saveLocale(Locale locale) =>
      writeString(_languageKey, locale.languageCode);
  Future<void> saveTheme(ThemeMode mode) => writeString(_themeKey, mode.name);
}
