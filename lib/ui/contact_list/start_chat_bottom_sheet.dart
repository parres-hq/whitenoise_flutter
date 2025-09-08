import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/follow_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/profile_ready_card_visibility_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/error.dart' show ApiError;
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/users.dart' as wn_users_api;
import 'package:whitenoise/ui/contact_list/widgets/share_invite_button.dart';
import 'package:whitenoise/ui/contact_list/widgets/share_invite_callout.dart';
import 'package:whitenoise/ui/contact_list/widgets/user_profile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

// User API interface for testing
abstract class WnUsersApi {
  Future<bool> userHasKeyPackage({required String pubkey});
}

// Default implementation that uses the real API
class DefaultWnUsersApi implements WnUsersApi {
  const DefaultWnUsersApi();

  @override
  Future<bool> userHasKeyPackage({required String pubkey}) {
    return wn_users_api.userHasKeyPackage(pubkey: pubkey);
  }
}

class StartChatBottomSheet extends ConsumerStatefulWidget {
  final ContactModel contact;
  final ValueChanged<Group?>? onChatCreated;
  final WnUsersApi? usersApi;

  const StartChatBottomSheet({
    super.key,
    required this.contact,
    this.onChatCreated,
    this.usersApi,
  });

  static Future<void> show({
    required BuildContext context,
    required ContactModel contact,
    ValueChanged<Group?>? onChatCreated,
  }) {
    return WnBottomSheet.show(
      context: context,
      title: 'User Profile',
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder: (context) => StartChatBottomSheet(contact: contact, onChatCreated: onChatCreated),
    );
  }

  @override
  ConsumerState<StartChatBottomSheet> createState() => _StartChatBottomSheetState();
}

class _StartChatBottomSheetState extends ConsumerState<StartChatBottomSheet> {
  final _logger = Logger('StartChatBottomSheet');
  bool _isCreatingGroup = false;
  bool _isLoadingKeyPackage = true;
  bool _isLoadingKeyPackageError = false;
  bool _needsInvite = false;

  @override
  void initState() {
    super.initState();
    _loadKeyPackage();
  }

  Future<void> _loadKeyPackage() async {
    final activeAccountState = await ref.read(activeAccountProvider.future);
    final activeAccount = activeAccountState.account;
    if (activeAccount == null) {
      ref.showErrorToast('No active account found');
      return;
    }
    try {
      final usersApi = widget.usersApi ?? const DefaultWnUsersApi();
      final userHasKeyPackage = await usersApi.userHasKeyPackage(pubkey: widget.contact.publicKey);
      if (mounted) {
        setState(() {
          _isLoadingKeyPackage = false;
          _needsInvite = userHasKeyPackage == false;
        });
      }
    } catch (e) {
      _logger.warning('Failed to fetch key package: $e');
      setState(() {
        _isLoadingKeyPackage = false;
        _needsInvite = true;
      });
    }
  }

  Future<void> _createOrOpenDirectMessageGroup() async {
    setState(() {
      _isCreatingGroup = true;
    });

    try {
      final group = await ref
          .read(groupsProvider.notifier)
          .createNewGroup(
            groupName: '',
            groupDescription: '',
            isDm: true,
            memberPublicKeyHexs: [widget.contact.publicKey],
            adminPublicKeyHexs: [widget.contact.publicKey],
          );

      if (group != null) {
        _logger.info('Direct message group created successfully: ${group.mlsGroupId}');

        if (mounted) {
          // Dismiss the ProfileReadyCard since user has successfully started a chat
          await ref.read(profileReadyCardVisibilityProvider.notifier).dismissCard();
          if (mounted) {
            Navigator.pop(context);
          }

          if (widget.onChatCreated != null) {
            widget.onChatCreated?.call(group);
          }

          ref.showSuccessToast(
            'Chat with ${widget.contact.displayName} started successfully',
          );
        }
      } else {
        // Group creation failed - check the provider state for the error message
        if (mounted) {
          final groupsState = ref.read(groupsProvider);
          final errorMessage = groupsState.error ?? 'Failed to create direct message group';
          ref.showErrorToast(errorMessage);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingGroup = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    final followNotifier = ref.read(followProvider(widget.contact.publicKey).notifier);
    var currentFollowState = ref.read(followProvider(widget.contact.publicKey));
    late String successMessage;
    if (currentFollowState.isFollowing) {
      successMessage = 'Unfollowed ${widget.contact.displayName}';
      await followNotifier.removeFollow(widget.contact.publicKey);
    } else {
      successMessage = 'Followed ${widget.contact.displayName}';
      await followNotifier.addFollow(widget.contact.publicKey);
    }

    currentFollowState = ref.read(followProvider(widget.contact.publicKey));
    final errorMessage = currentFollowState.error ?? '';
    if (errorMessage.isNotEmpty) {
      ref.showErrorToast(errorMessage);
    } else {
      ref.showSuccessToast(successMessage);
    }
  }

  void _openAddToGroup() {
    if (widget.contact.publicKey.isEmpty) {
      ref.showErrorToast('No user to add to group');
      return;
    }
    context.push('/add_to_group/${widget.contact.publicKey}');
  }

  @override
  Widget build(BuildContext context) {
    final followState = ref.watch(followProvider(widget.contact.publicKey));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              Gap(12.h),
              UserProfile(
                imageUrl: widget.contact.imagePath ?? '',
                name: widget.contact.displayName,
                nip05: widget.contact.nip05 ?? '',
                pubkey: widget.contact.publicKey,
                ref: ref,
              ),
              Gap(36.h),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child:
                _isLoadingKeyPackageError
                    ? const SizedBox.shrink(key: ValueKey('error'))
                    : _isLoadingKeyPackage
                    ? Center(
                      key: const ValueKey('loading'),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.h),
                        child: SizedBox(
                          width: 32.w,
                          height: 32.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.0,
                            valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                          ),
                        ),
                      ),
                    )
                    : _needsInvite
                    ? Column(
                      key: const ValueKey('invite'),
                      children: [
                        ShareInviteCallout(contact: widget.contact),
                        Gap(10.h),
                        const ShareInviteButton(),
                      ],
                    )
                    : Column(
                      key: const ValueKey('buttons'),
                      children: [
                        WnFilledButton(
                          visualState: WnButtonVisualState.secondary,
                          onPressed: followState.isLoading ? null : _toggleFollow,
                          loading: followState.isLoading,
                          label: followState.isFollowing ? 'Unfollow' : 'Follow',
                          suffixIcon: SvgPicture.asset(
                            followState.isFollowing
                                ? AssetsPaths.icRemoveUser
                                : AssetsPaths.icAddUser,
                            width: 18.w,
                            height: 18.w,
                            colorFilter: ColorFilter.mode(
                              context.colors.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        Gap(8.h),
                        WnFilledButton(
                          visualState: WnButtonVisualState.secondary,
                          onPressed: _openAddToGroup,
                          label: 'Add to Group',
                          suffixIcon: WnImage(
                            AssetsPaths.icChatInvite,
                            size: 18.w,
                            color: context.colors.primary,
                          ),
                        ),
                        Gap(8.h),
                        WnFilledButton(
                          onPressed: _isCreatingGroup ? null : _createOrOpenDirectMessageGroup,
                          loading: _isCreatingGroup,
                          label: _isCreatingGroup ? 'Creating Chat...' : 'Start Chat',
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }
}
