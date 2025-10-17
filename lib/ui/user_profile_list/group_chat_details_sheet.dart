import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/create_group_provider.dart';
import 'package:whitenoise/config/states/create_group_state.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_text_field.dart';
import 'package:whitenoise/ui/settings/profile/widgets/edit_icon.dart';
import 'package:whitenoise/ui/user_profile_list/safe_toast_mixin.dart';
import 'package:whitenoise/ui/user_profile_list/share_invite_bottom_sheet.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class GroupChatDetailsSheet extends ConsumerStatefulWidget {
  const GroupChatDetailsSheet({
    super.key,
    required this.selectedUserProfiles,
    this.onGroupCreated,
  });

  final List<UserProfile> selectedUserProfiles;
  final ValueChanged<Group?>? onGroupCreated;

  static Future<void> show({
    required BuildContext context,
    required List<UserProfile> selectedUserProfiles,
    ValueChanged<Group?>? onGroupCreated,
  }) {
    return WnBottomSheet.show(
      context: context,
      title: 'ui.groupChatDetails'.tr(),
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder:
          (context) => GroupChatDetailsSheet(
            selectedUserProfiles: selectedUserProfiles,
            onGroupCreated: onGroupCreated,
          ),
    );
  }

  @override
  ConsumerState<GroupChatDetailsSheet> createState() => _GroupChatDetailsSheetState();
}

class _GroupChatDetailsSheetState extends ConsumerState<GroupChatDetailsSheet> with SafeToastMixin {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  Group? createdGroup;
  @override
  void initState() {
    super.initState();
    _groupNameController.addListener(_onGroupNameChanged);
    _groupDescriptionController.addListener(_onGroupDescriptionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(createGroupProvider.notifier)
          .filterUserProfilesWithKeyPackage(widget.selectedUserProfiles);
    });
  }

  void _onGroupNameChanged() {
    ref.read(createGroupProvider.notifier).updateGroupName(_groupNameController.text);
  }

  void _onGroupDescriptionChanged() {
    ref.read(createGroupProvider.notifier).updateGroupDescription(_groupDescriptionController.text);
  }

  Future<void> _pickGroupImage() async {
    await ref.read(createGroupProvider.notifier).pickGroupImage();
  }

  void _createGroupChat() async {
    await ref
        .read(createGroupProvider.notifier)
        .createGroup(
          onGroupCreated: (createdGroup) {
            if (createdGroup != null && mounted) {
              this.createdGroup = createdGroup;
              context.pop();
            }
          },
        );
  }

  void _showInviteSheet(CreateGroupState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          await ShareInviteBottomSheet.show(
            context: context,
            userProfiles: state.userProfilesWithoutKeyPackage,
          );
        } catch (e, st) {
          Logger('GroupChatDetailsSheet').severe('Error showing invite sheet', e, st);
          safeShowErrorToast('errors.errorOccurredTryAgain'.tr());
        } finally {
          ref.read(createGroupProvider.notifier).dismissInviteSheet();
        }
      }
    });
  }

  void _goToChat() {
    if (createdGroup != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) async {
          if (mounted) {
            Routes.goToChat(context, createdGroup!.mlsGroupId);
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _groupNameController.removeListener(_onGroupNameChanged);
    _groupDescriptionController.removeListener(_onGroupDescriptionChanged);
    _groupDescriptionController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createGroupProvider, (previous, next) {
      if (next.error != null) {
        safeShowErrorToast(next.error!);
        ref.read(createGroupProvider.notifier).clearError();
      }
      if (next.shouldShowInviteSheet && next.userProfilesWithoutKeyPackage.isNotEmpty) {
        _showInviteSheet(next);
      }
    });

    final state = ref.watch(createGroupProvider);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(createGroupProvider.notifier).discardChanges();
          _goToChat();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _groupNameController,
                  builder: (context, value, child) {
                    final displayName = value.text.trim();
                    return WnAvatar(
                      imageUrl: state.selectedImagePath ?? '',
                      displayName: displayName,
                      size: 96.w,
                      showBorder: true,
                    );
                  },
                ),
                Positioned(
                  right: 5.w,
                  bottom: 4.h,
                  width: 28.w,
                  child: WnEditIconWidget(
                    onTap: _pickGroupImage,
                  ),
                ),
              ],
            ),
          ),
          Gap(24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ui.groupName'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.primary,
                  ),
                ),
                Gap(8.h),
                WnTextField(
                  textController: _groupNameController,
                  hintText: 'ui.groupNameHint'.tr(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Gap(24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ui.groupDescription'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.primary,
                  ),
                ),
                Gap(8.h),
                WnTextField(
                  textController: _groupDescriptionController,
                  hintText: 'ui.groupDescriptionHint'.tr(),
                  maxLines: 5,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          Gap(24.h),
          Text(
            'ui.invitingMembers'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.colors.mutedForeground,
            ),
          ),
          Gap(12.h),
          Wrap(
            runSpacing: 8.h,
            spacing: 8.w,
            alignment: WrapAlignment.center,
            children:
                state.userProfilesWithKeyPackage
                    .map(
                      (userProfile) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: context.colors.avatarSurface,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            WnAvatar(
                              imageUrl: userProfile.imagePath ?? '',
                              displayName: userProfile.displayName,
                              size: 30.w,
                              showBorder: true,
                            ),
                            Gap(8.w),
                            SizedBox(
                              width: 104.w,
                              child: Text(
                                userProfile.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
          const Spacer(),
          WnFilledButton(
            onPressed: state.canCreateGroup ? _createGroupChat : null,
            loading: state.isCreatingGroup || state.isUploadingImage,
            label:
                state.isUploadingImage
                    ? 'ui.uploadingImage'.tr()
                    : state.isCreatingGroup
                    ? 'ui.creatingGroup'.tr()
                    : 'ui.createGroup'.tr(),
          ),
        ],
      ),
    );
  }
}
