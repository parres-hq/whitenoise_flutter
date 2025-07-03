import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/profile/connect_profile_bottom_sheet.dart';

class SwitchProfileBottomSheet extends ConsumerWidget {
  final List<ContactModel> profiles;
  final Function(ContactModel) onProfileSelected;

  const SwitchProfileBottomSheet({
    super.key,
    required this.profiles,
    required this.onProfileSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required List<ContactModel> profiles,
    required Function(ContactModel) onProfileSelected,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Profiles',
      wrapContent: true,
      maxHeight: 0.65.sh,
      builder:
          (context) => SwitchProfileBottomSheet(
            profiles: profiles,
            onProfileSelected: onProfileSelected,
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAccountPubkey = ref.watch(activeAccountProvider);

    // Sort profiles: active account first, then others
    final sortedProfiles = [...profiles];
    if (activeAccountPubkey != null) {
      sortedProfiles.sort((a, b) {
        final aIsActive = a.publicKey == activeAccountPubkey;
        final bIsActive = b.publicKey == activeAccountPubkey;

        if (aIsActive && !bIsActive) return -1;
        if (!aIsActive && bIsActive) return 1;
        return 0;
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: sortedProfiles.length,
            itemBuilder: (context, index) {
              final profile = sortedProfiles[index];
              final isActiveAccount = profile.publicKey == activeAccountPubkey;

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                decoration:
                    isActiveAccount
                        ? BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.1),
                        )
                        : null,
                child: ContactListTile(
                  contact: profile,
                  onTap: () {
                    if (isActiveAccount) {
                      ref.showRawErrorToast('This profile is already active.');
                    } else {
                      onProfileSelected(profile);
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: AppFilledButton(
            title: 'Connect Another Profile',
            onPressed: () {
              context.pop();
              ConnectProfileBottomSheet.show(context: context);
            },
          ),
        ),
        Gap(8.h),
      ],
    );
  }
}
