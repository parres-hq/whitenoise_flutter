import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/config/states/theme_state.dart';

class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    Future.microtask(() => _loadThemeMode());
    return const ThemeState();
  }

  final _logger = Logger('ThemeNotifier');
  static const String _themePreferenceKey = 'theme_mode';

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themePreferenceKey);

      if (themeModeIndex != null) {
        final themeMode = ThemeMode.values[themeModeIndex];
        state = state.copyWith(themeMode: themeMode);
        _logger.info('Loaded theme mode: ${themeMode.name}');
      } else {
        _logger.info('No saved theme mode, using system default');
      }
    } catch (e, st) {
      _logger.severe('Failed to load theme mode', e, st);
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePreferenceKey, themeMode.index);
      state = state.copyWith(themeMode: themeMode);
      _logger.info('Theme mode set to: ${themeMode.name}');
    } catch (e, st) {
      _logger.severe('Failed to save theme mode', e, st);
    }
  }

  Future<void> toggleThemeMode() async {
    final newMode = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    await setThemeMode(newMode);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);
