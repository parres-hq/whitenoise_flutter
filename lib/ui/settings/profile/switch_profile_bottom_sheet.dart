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

class SwitchProfileBottomSheet extends ConsumerStatefulWidget {
  final List<ContactModel> profiles;
  final Function(ContactModel) onProfileSelected;
  final bool isDismissible;
  final bool showSuccessToast;

  const SwitchProfileBottomSheet({
    super.key,
    required this.profiles,
    required this.onProfileSelected,
    this.isDismissible = true,
    this.showSuccessToast = false,
  });

  /// dismissible is used to make sure the user chooses a profile
  /// showSuccessToast is used to determine if the account switcher is shown because of logout
  static Future<void> show({
    required BuildContext context,
    required List<ContactModel> profiles,
    required Function(ContactModel) onProfileSelected,
    bool isDismissible = true,
    bool showSuccessToast = false,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Profiles',
      wrapContent: true,
      maxHeight: 0.65.sh,
      barrierDismissible: isDismissible,
      showCloseButton: isDismissible,
      builder:
          (context) => SwitchProfileBottomSheet(
            profiles: profiles,
            onProfileSelected: onProfileSelected,
            isDismissible: isDismissible,
            showSuccessToast: showSuccessToast,
          ),
    );
  }

  @override
  ConsumerState<SwitchProfileBottomSheet> createState() => _SwitchProfileBottomSheetState();
}

class _SwitchProfileBottomSheetState extends ConsumerState<SwitchProfileBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showSuccessToast) {
        ref.showRawSuccessToast('Signed out. Choose different profile.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeAccountPubkey = ref.watch(activeAccountProvider);

    // Sort profiles: active account first, then others
    final sortedProfiles = [...widget.profiles];
    if (activeAccountPubkey != null) {
      sortedProfiles.sort((a, b) {
        final aIsActive = a.publicKey == activeAccountPubkey;
        final bIsActive = b.publicKey == activeAccountPubkey;

        if (aIsActive && !bIsActive) return -1;
        if (!aIsActive && bIsActive) return 1;
        return 0;
      });
    }

    return PopScope(
      canPop: widget.isDismissible,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
              itemCount: sortedProfiles.length,
              itemBuilder: (context, index) {
                final profile = sortedProfiles[index];
                final isActiveAccount = profile.publicKey == activeAccountPubkey;

                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
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
                      if (isActiveAccount && !widget.showSuccessToast) {
                        ref.showRawErrorToast('This profile is already active.');
                      } else {
                        widget.onProfileSelected(profile);
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Gap(8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: AppFilledButton(
              title: 'Connect Another Profile',
              onPressed: () {
                if (widget.isDismissible) {
                  context.pop();
                  ConnectProfileBottomSheet.show(context: context);
                } else {
                  // For non-dismissible mode, show connect profile without popping
                  ConnectProfileBottomSheet.show(context: context);
                }
              },
            ),
          ),
          Gap(16.h),
        ],
      ),
    );
  }
}
