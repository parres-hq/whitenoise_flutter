import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/localization_provider.dart';
import 'package:whitenoise/services/localization_service.dart';

/// Extension on String for easy translation
extension StringLocalization on String {
  /// Translate this string using the localization service
  String tr([Map<String, dynamic>? params]) {
    return LocalizationService.translate(this, params: params);
  }
}

/// Extension on BuildContext for easy translation access
extension BuildContextLocalization on BuildContext {
  /// Get current locale
  Locale get locale {
    try {
      return Localizations.localeOf(this);
    } catch (e) {
      return Locale(LocalizationService.currentLocale);
    }
  }

  /// Translate a key with context
  String tr(String key, [Map<String, dynamic>? params]) {
    return LocalizationService.translate(key, params: params);
  }
}

/// Consumer widget that rebuilds when locale changes
class LocalizedText extends ConsumerWidget {
  final String translationKey;
  final Map<String, dynamic>? params;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  const LocalizedText(
    this.translationKey, {
    super.key,
    this.params,
    this.style,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch locale changes to rebuild automatically
    ref.watch(currentLocaleProvider);

    return Text(
      translationKey.tr(params),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
}
