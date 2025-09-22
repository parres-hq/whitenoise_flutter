import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/user_profile_data_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' show Account, getAccounts;
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/settings/profile/connect_profile_bottom_sheet.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';

class SwitchProfileBottomSheet extends ConsumerStatefulWidget {
  final Function(ContactModel) onProfileSelected;
  final bool isDismissible;
  final bool showSuccessToast;

  const SwitchProfileBottomSheet({
    super.key,
    required this.onProfileSelected,
    this.isDismissible = true,
    this.showSuccessToast = false,
  });

  /// dismissible is used to make sure the user chooses a profile
  /// showSuccessToast is used to determine if the account switcher is shown because of logout
  static Future<void> show({
    required BuildContext context,
    required Function(ContactModel) onProfileSelected,
    bool isDismissible = true,
    bool showSuccessToast = false,
  }) {
    return WnBottomSheet.show(
      context: context,
      title: 'Profiles',
      barrierDismissible: isDismissible,
      showCloseButton: isDismissible,
      builder:
          (context) => SwitchProfileBottomSheet(
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
  bool _isConnectProfileSheetOpen = false;
  bool _isLoadingAccounts = true;
  List<ContactModel> _accountsProfileData = [];
  // Cache for converting any npub profile key to hex for quick sync comparisons
  final Map<String, String> _pubkeyToHex = {};

  /// Precompute and cache hex versions of all loaded profile keys
  void _precomputeProfileHexes() {
    for (final profile in _accountsProfileData) {
      final originalPubKey = profile.publicKey;
      if (_pubkeyToHex.containsKey(originalPubKey)) continue;
      final hexPubkey = PubkeyFormatter(pubkey: originalPubKey).toHex();
      if (hexPubkey == null) continue;
      _pubkeyToHex[originalPubKey] = hexPubkey;
    }
  }

  /// Sort to show active account first, then others
  void _sortAccountsProfileData() {
    _precomputeProfileHexes();
    if (_activeAccountHex != null) {
      _accountsProfileData.sort((a, b) {
        final aHex = _pubkeyToHex[a.publicKey] ?? a.publicKey;
        final bHex = _pubkeyToHex[b.publicKey] ?? b.publicKey;
        final aIsActive = aHex == _activeAccountHex;
        final bIsActive = bHex == _activeAccountHex;
        if (aIsActive && !bIsActive) return -1;
        if (!aIsActive && bIsActive) return 1;
        return 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getActivePubkeyHex();
    _loadAccountsProfileData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showSuccessToast) {
        ref.showRawSuccessToast('Signed out. Choose different profile.');
      }
    });
  }

  Future<void> _loadAccountsProfileData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAccounts = true;
    });

    try {
      final List<Account> accounts = await getAccounts();
      final UserProfileDataNotifier userProfileDataNotifier = ref.read(
        userProfileDataProvider.notifier,
      );
      final List<Future<ContactModel>> accountsProfileDataFutures =
          accounts
              .map((account) => userProfileDataNotifier.getUserProfileData(account.pubkey))
              .toList();
      final List<ContactModel> accountsProfileData = await Future.wait(accountsProfileDataFutures);

      if (!mounted) return;
      setState(() {
        _accountsProfileData = accountsProfileData;
        _isLoadingAccounts = false;
      });
      _sortAccountsProfileData();
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to load accounts');
        setState(() {
          _isLoadingAccounts = false;
        });
      }
    }
  }

  Future<void> _getActivePubkeyHex() async {
    final activeAccountPubkey = ref.read(activePubkeyProvider) ?? '';
    if (activeAccountPubkey.isNotEmpty) {
      setState(() {
        _activeAccountHex = activeAccountPubkey;
      });
    }
  }

  Future<bool> _isActiveAccount(ContactModel profile) async {
    if (_activeAccountHex == null) return false;

    try {
      final String profileHex = PubkeyFormatter(pubkey: profile.publicKey).toHex() ?? '';
      return profileHex == _activeAccountHex;
    } catch (e) {
      // If conversion fails, try direct comparison as fallback
      return profile.publicKey == _activeAccountHex;
    }
  }

  /// Returns true if the ConnectProfileBottomSheet is currently open
  bool get isConnectProfileSheetOpen => _isConnectProfileSheetOpen;

  /// Handles opening the ConnectProfileBottomSheet and managing visibility state
  Future<void> _handleConnectAnotherProfile() async {
    setState(() {
      _isConnectProfileSheetOpen = true;
    });

    try {
      await ConnectProfileBottomSheet.show(context: context);
    } finally {
      if (mounted) {
        setState(() {
          _isConnectProfileSheetOpen = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.isDismissible,
      child: Visibility(
        visible: !_isConnectProfileSheetOpen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoadingAccounts)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: Center(
                  child: CircularProgressIndicator(
                    color: context.colors.primary,
                  ),
                ),
              )
            else ...[
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(bottom: 16.h),
                  itemCount: _accountsProfileData.length,
                  itemBuilder: (context, index) {
                    final profile = _accountsProfileData[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 2.h,
                      ),
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
                            child: ContactListTile(
                              contact: profile,
                              onTap: () {
                                if (isActiveAccount && !widget.showSuccessToast) {
                                  // Just close the sheet if selecting the currently active profile
                                  Navigator.pop(context);
                                } else {
                                  widget.onProfileSelected(profile);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Gap(4.h),
              WnFilledButton(
                label: 'Connect Another Profile',
                onPressed: _handleConnectAnotherProfile,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
