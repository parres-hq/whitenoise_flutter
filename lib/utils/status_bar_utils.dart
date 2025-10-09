import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utility class for managing status bar styles across the app.
class StatusBarUtils {
  /// Wraps a widget with theme-aware status bar icons.
  /// - Light mode: dark icons for light backgrounds
  /// - Dark mode: light icons for dark backgrounds
  /// Use this for screens that adapt their background color to the theme
  /// (e.g., auth flow screens).
  static Widget wrapWithAdaptiveIcons(BuildContext context, Widget child) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      child: child,
    );
  }
}
