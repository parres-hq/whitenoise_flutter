import 'dart:io';

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
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_field.dart';

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

  @override
  void initState() {
    super.initState();
    _groupNameController.addListener(_onGroupNameChanged);
  }

  void _onGroupNameChanged() {
    ref.read(createGroupProvider.notifier).updateGroupName(_groupNameController.text);
  }

  Future<void> _pickGroupImage() async {
    await ref.read(createGroupProvider.notifier).pickGroupImage();
  }

  void _createGroupChat() async {
    await ref
        .read(createGroupProvider.notifier)
        .filterContactsAndCreateGroup(
          selectedContacts: widget.selectedContacts,
          onGroupCreated: (createdGroup) {
            if (createdGroup != null && mounted) {
              context.pop();

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (mounted) {
                  context.go(Routes.home);
                  await Future.delayed(const Duration(milliseconds: 150));
                  if (mounted) {
                    Routes.goToChat(context, createdGroup.mlsGroupId);
                  }
                }
              });
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: state.isCreatingGroup || state.isUploadingImage ? null : _pickGroupImage,
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: context.colors.baseMuted,
                      shape: BoxShape.circle,
                    ),
                    child:
                        state.selectedImagePath != null && state.selectedImagePath!.isNotEmpty
                            ? ClipOval(
                              child: Image.file(
                                File(state.selectedImagePath!),
                                width: 80.w,
                                height: 80.w,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80.w,
                                    height: 80.w,
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      color: context.colors.baseMuted,
                                      shape: BoxShape.circle,
                                    ),
                                    child: WnImage(
                                      AssetsPaths.icCamera,
                                      size: 42.w,
                                      color: context.colors.mutedForeground,
                                    ),
                                  );
                                },
                              ),
                            )
                            : Padding(
                              padding: EdgeInsets.all(16.w),
                              child: WnImage(
                                AssetsPaths.icCamera,
                                size: 42.w,
                                color: context.colors.mutedForeground,
                              ),
                            ),
                  ),
                ),
                if (state.isUploadingImage)
                  Positioned.fill(
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.colors.solidPrimary,
                            ),
                          ),
                        ),
                      ),
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
                  'Group chat name',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.primary,
                  ),
                ),
                Gap(8.h),
                WnTextField(
                  textController: _groupNameController,
                  hintText: 'Enter group name',
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Gap(24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'Members',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: context.colors.primary,
              ),
            ),
          ),
          Gap(8.h),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: widget.selectedContacts.length,
              itemBuilder: (context, index) {
                final contact = widget.selectedContacts[index];
                return ContactListTile(contact: contact);
              },
            ),
          ),
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
        ],
      ),
    );
  }
}
