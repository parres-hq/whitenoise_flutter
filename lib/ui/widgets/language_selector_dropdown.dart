import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/localization_provider.dart';
import 'package:whitenoise/services/localization_service.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class LanguageSelectorDropdown extends ConsumerStatefulWidget {
  const LanguageSelectorDropdown({super.key});

  @override
  ConsumerState<LanguageSelectorDropdown> createState() => _LanguageSelectorDropdownState();
}

class _LanguageSelectorDropdownState extends ConsumerState<LanguageSelectorDropdown> {
  bool isExpanded = false;

  String getLanguageText(String languageCode) {
    final localizationNotifier = ref.read(localizationProvider.notifier);
    if (languageCode == 'system') {
      return localizationNotifier.selectedLanguageDisplayName;
    }
    return LocalizationService.supportedLocales[languageCode] ?? languageCode.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final localizationState = ref.watch(localizationProvider);
    final localizationNotifier = ref.read(localizationProvider.notifier);
    final selectedLanguage = localizationState.selectedLanguage;
    final supportedLocales = localizationNotifier.supportedLocales;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Container(
            height: 56.h,
            decoration: BoxDecoration(
              color: context.colors.avatarSurface,
              border: Border.all(color: context.colors.border),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 16.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getLanguageText(selectedLanguage),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
                WnImage(
                  isExpanded ? AssetsPaths.icChevronUp : AssetsPaths.icChevronDown,
                  size: 20.w,
                  color: context.colors.primary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          Gap(8.h),
          Container(
            decoration: BoxDecoration(
              color: context.colors.avatarSurface,
              border: Border.all(
                color: context.colors.border,
                width: 1.w,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:
                  supportedLocales.entries.map((locale) {
                    return _LanguageOption(
                      localeCode: locale.key,
                      text: getLanguageText(locale.key),
                      isSelected: locale.key == selectedLanguage,
                      onTap: () async {
                        if (locale.key != selectedLanguage) {
                          await localizationNotifier.changeLocale(locale.key);
                          setState(() {
                            isExpanded = false;
                          });
                        }
                      },
                    );
                  }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String localeCode;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.localeCode,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(6.w),
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 16.h,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? context.colors.primary.withValues(alpha: 0.1)
                  : context.colors.avatarSurface,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? context.colors.primary : context.colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
