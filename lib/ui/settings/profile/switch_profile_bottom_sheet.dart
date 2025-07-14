import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
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
  String? _activeAccountHex;
  String? _loadingProfileKey; // Track which profile is being loaded

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showSuccessToast) {
        ref.showRawSuccessToast('Signed out. Choose different profile.');
      }
      _loadActiveAccountHex();
    });
  }

  Future<void> _loadActiveAccountHex() async {
    final activeAccountPubkey = ref.read(activeAccountProvider);
    if (activeAccountPubkey != null) {
      setState(() {
        _activeAccountHex = activeAccountPubkey;
      });
    }
  }

  Future<bool> _isActiveAccount(ContactModel profile) async {
    if (_activeAccountHex == null) return false;

    try {
      // Convert profile's npub key to hex for comparison
      String profileHex = profile.publicKey;
      if (profile.publicKey.startsWith('npub1')) {
        profileHex = await hexPubkeyFromNpub(npub: profile.publicKey);
      }

      return profileHex == _activeAccountHex;
    } catch (e) {
      // If conversion fails, try direct comparison as fallback
      return profile.publicKey == _activeAccountHex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAccountPubkey = ref.watch(activeAccountProvider);

    // Sort profiles: active account first, then others
    final sortedProfiles = [...widget.profiles];
    if (activeAccountPubkey != null) {
      sortedProfiles.sort((a, b) {
        // Use cached _activeAccountHex for sorting if available
        final aIsActive =
            _activeAccountHex != null &&
            (a.publicKey == _activeAccountHex ||
                a.publicKey.startsWith('npub1')); // Will be resolved async
        final bIsActive =
            _activeAccountHex != null &&
            (b.publicKey == _activeAccountHex ||
                b.publicKey.startsWith('npub1')); // Will be resolved async

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

                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
                  child: FutureBuilder<bool>(
                    future: _isActiveAccount(profile),
                    builder: (context, snapshot) {
                      final isActiveAccount = snapshot.data ?? false;

                      return Container(
                        decoration:
                            isActiveAccount
                                ? BoxDecoration(
                                  color: context.colors.primary.withValues(alpha: 0.1),
                                )
                                : null,
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        child: Stack(
                          children: [
                            ContactListTile(
                              contact: profile,
                              onTap:
                                  _loadingProfileKey != null
                                      ? null // Disable all taps when any profile is loading
                                      : () async {
                                        if (isActiveAccount && !widget.showSuccessToast) {
                                          // Just close the sheet if selecting the currently active profile
                                          Navigator.pop(context);
                                        } else {
                                          // Show loading state for this profile
                                          setState(() {
                                            _loadingProfileKey = profile.publicKey;
                                          });

                                          // Call the profile selection handler and wait for completion
                                          try {
                                            widget.onProfileSelected(profile);
                                            // Don't close the sheet here - let the parent handle navigation
                                            // after the account switch is complete
                                          } catch (e) {
                                            // Reset loading state on error
                                            if (mounted) {
                                              setState(() {
                                                _loadingProfileKey = null;
                                              });
                                            }
                                          }
                                        }
                                      },
                            ),
                            if (_loadingProfileKey == profile.publicKey)
                              Positioned(
                                right: 16.w,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Gap(4.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: AppFilledButton(
              title: 'Connect Another Profile',
              onPressed:
                  _loadingProfileKey != null
                      ? null // Disable button when any profile is loading
                      : () {
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
