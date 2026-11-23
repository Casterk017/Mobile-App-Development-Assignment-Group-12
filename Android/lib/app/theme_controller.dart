import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({
    ThemeMode initialMode = ThemeMode.system,
    this.savePreference,
  }) : _mode = initialMode;
  final Future<void> Function(ThemeMode)? savePreference;
  ThemeMode _mode;
  bool _saving = false;
  bool _disposed = false;
  ThemeMode get mode => _mode;
  bool get saving => _saving;
  Future<void> select(ThemeMode value) async {
    if (_saving || value == _mode) return;
    _saving = true;
    notifyListeners();
    try {
      await savePreference?.call(value);
      if (!_disposed) _mode = value;
    } finally {
      if (!_disposed) {
        _saving = false;
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
