import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/create_group_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/contact_list/safe_toast_mixin.dart';
import 'package:whitenoise/ui/contact_list/share_invite_bottom_sheet.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_text_field.dart';
import 'package:whitenoise/ui/settings/profile/widgets/edit_icon.dart';

class GroupChatDetailsSheet extends ConsumerStatefulWidget {
  const GroupChatDetailsSheet({
    super.key,
    required this.selectedContacts,
    this.onGroupCreated,
  });

  final List<ContactModel> selectedContacts;
  final ValueChanged<Group?>? onGroupCreated;

  static Future<void> show({
    required BuildContext context,
    required List<ContactModel> selectedContacts,
    ValueChanged<Group?>? onGroupCreated,
  }) {
    return WnBottomSheet.show(
      context: context,
      title: 'Group chat details',
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder:
          (context) => GroupChatDetailsSheet(
            selectedContacts: selectedContacts,
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

  @override
  void initState() {
    super.initState();
    _groupNameController.addListener(_onGroupNameChanged);
    _groupDescriptionController.addListener(_onGroupDescriptionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createGroupProvider.notifier).filterContactsWithKeyPackage(widget.selectedContacts);
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
              context.pop();
              WidgetsBinding.instance.addPostFrameCallback(
                (_) async {
                  if (mounted) {
                    context.go(Routes.home);
                    await Future.delayed(const Duration(milliseconds: 150));
                    if (mounted) {
                      Routes.goToChat(context, createdGroup.mlsGroupId);
                    }
                  }
                },
              );
            }
          },
        );
  }

  @override
  void dispose() {
    _groupNameController.removeListener(_onGroupNameChanged);
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createGroupProvider);

    ref.listen(createGroupProvider, (previous, next) {
      if (next.error != null) {
        safeShowErrorToast(next.error!);
        ref.read(createGroupProvider.notifier).clearError();
      }

      if (next.shouldShowInviteSheet && next.contactsWithoutKeyPackage.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            try {
              await ShareInviteBottomSheet.show(
                context: context,
                contacts: next.contactsWithoutKeyPackage,
              );
            } catch (e) {
              safeShowErrorToast('Failed to show share invite bottom sheet: $e');
            } finally {
              ref.read(createGroupProvider.notifier).dismissInviteSheet();
            }
          }
        });
      }
    });

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(createGroupProvider.notifier).discardChanges();
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
                  'Group Name:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.primary,
                  ),
                ),
                Gap(8.h),
                WnTextField(
                  textController: _groupNameController,
                  hintText: 'Free Citizen Group',
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
                  'Group Description :',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.primary,
                  ),
                ),
                Gap(8.h),
                WnTextField(
                  textController: _groupDescriptionController,
                  hintText: 'Write something about the group',
                  maxLines: 5,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          Gap(24.h),
          Text(
            'Inviting Members:',
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
                state.contactsWithKeyPackage
                    .map(
                      (contact) => Container(
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
                              imageUrl: contact.imagePath ?? '',
                              displayName: contact.displayName,
                              size: 30.w,
                              showBorder: true,
                            ),
                            Gap(8.w),
                            SizedBox(
                              width: 104.w,
                              child: Text(
                                contact.displayName,
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
                    ? 'Uploading Image...'
                    : state.isCreatingGroup
                    ? 'Creating Group...'
                    : 'Create Group',
          ),
          Gap(16.h),
        ],
      ),
    );
  }
}
