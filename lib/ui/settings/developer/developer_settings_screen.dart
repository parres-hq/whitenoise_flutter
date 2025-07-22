import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';

class DeveloperSettingsScreen extends ConsumerStatefulWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  ConsumerState<DeveloperSettingsScreen> createState() => _DeveloperSettingsScreenState();

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeveloperSettingsScreen(),
      ),
    );
  }
}

class _DeveloperSettingsScreenState extends ConsumerState<DeveloperSettingsScreen> {
  bool _isLoading = false;

  Future<void> _clearMetadataCache() async {
    setState(() => _isLoading = true);

    try {
      ref.read(metadataCacheProvider.notifier).clearCache();
      ref.showSuccessToast('Metadata cache cleared successfully');
    } catch (e) {
      ref.showErrorToast('Failed to clear cache: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reloadContacts() async {
    setState(() => _isLoading = true);

    try {
      final activeAccount = await ref.read(activeAccountProvider.notifier).getActiveAccountData();

      if (activeAccount != null) {
        await ref.read(contactsProvider.notifier).loadContacts(activeAccount.pubkey);
        ref.showSuccessToast('Contacts reloaded successfully');
      } else {
        ref.showErrorToast('No active account found');
      }
    } catch (e) {
      ref.showErrorToast('Failed to reload contacts: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.colors.appBarBackground,
        body: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: context.colors.neutral,
            child: Column(
              children: [
                Gap(20.h),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: SvgPicture.asset(
                        AssetsPaths.icChevronLeft,
                        colorFilter: ColorFilter.mode(
                          context.colors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    Text(
                      'Developer Settings',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: context.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Actions
                        Text(
                          'Actions',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primarySolid,
                          ),
                        ),
                        Gap(12.h),

                        WnFilledButton(
                          title: 'Clear Cache',
                          onPressed: _isLoading ? null : _clearMetadataCache,
                          loading: _isLoading,
                          visualState: WnButtonVisualState.error,
                        ),

                        Gap(8.h),

                        WnFilledButton(
                          title: 'Reload Contacts',
                          onPressed: _isLoading ? null : _reloadContacts,
                          loading: _isLoading,
                        ),
                        Gap(MediaQuery.of(context).padding.bottom),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
