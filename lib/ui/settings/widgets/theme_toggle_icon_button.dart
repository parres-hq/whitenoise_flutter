import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/theme_provider.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class ThemeToggleIconButton extends ConsumerWidget {
  const ThemeToggleIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    // Determine which icon to show based on current theme mode
    IconData icon;
    if (themeState.themeMode == ThemeMode.dark) {
      icon = Icons.dark_mode;
    } else if (themeState.themeMode == ThemeMode.light) {
      icon = Icons.light_mode;
    } else {
      // System theme
      icon = Icons.brightness_auto;
    }

    return IconButton(
      icon: Icon(icon, color: context.colors.appBarForeground),
      tooltip: 'Toggle theme mode',
      onPressed: () {
        // Cycle through theme modes: system -> light -> dark -> system
        ThemeMode nextMode;
        switch (themeState.themeMode) {
          case ThemeMode.system:
            nextMode = ThemeMode.light;
            break;
          case ThemeMode.light:
            nextMode = ThemeMode.dark;
            break;
          case ThemeMode.dark:
            nextMode = ThemeMode.system;
            break;
        }
        themeNotifier.setThemeMode(nextMode);
      },
    );
  }
}
