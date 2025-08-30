import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';
import 'package:whitenoise/utils/string_extensions.dart';

import 'member_action_buttons.dart';

class GroupMemberBottomSheet extends ConsumerStatefulWidget {
  const GroupMemberBottomSheet({
    super.key,
    required this.member,
    required this.groupId,
  });
  final User member;
  final String groupId;

  static void show(BuildContext context, {required String groupId, required User member}) {
    WnBottomSheet.show(
      context: context,
      title: 'Member',
      builder: (context) => GroupMemberBottomSheet(groupId: groupId, member: member),
    );
  }

  @override
  ConsumerState<GroupMemberBottomSheet> createState() => _GroupMemberBottomSheetState();
}

class _GroupMemberBottomSheetState extends ConsumerState<GroupMemberBottomSheet> {
  String currentUserNpub = '';
  bool _isRemoving = false;

  void _copyToClipboard() {
    final npub = widget.member.publicKey;
    ClipboardUtils.copyWithToast(
      ref: ref,
      textToCopy: npub,
      successMessage: 'Public key copied',
      noTextMessage: 'No public key to copy',
    );
  }

  void _openAddToGroup() {
    if (widget.member.publicKey.isEmpty) {
      ref.showErrorToast('No user to add to group');
      return;
    }
    context.push('/add_to_group/${widget.member.publicKey}');
  }

  void _loadCurrentUserNpub() async {
    final activeAccountPubkey = ref.read(activePubkeyProvider);
    if (activeAccountPubkey != null) {
      currentUserNpub = await activeAccountPubkey.toNpub() ?? '';
      setState(() {});
    }
  }

  Future<void> _removeFromGroup() async {
    setState(() {
      _isRemoving = true;
    });

    try {
      await ref
          .read(groupsProvider.notifier)
          .removeFromGroup(
            groupId: widget.groupId,
            membersNpubs: [widget.member.publicKey],
          );
      if (mounted) {
        Navigator.pop(context, true);
        ref.showSuccessToast('${widget.member.displayName} removed from group');
      }
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to remove member: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });
      }
    }
  }

  Future<bool?> _openRemoveFromGroupDialog() => showDialog<bool>(
    context: context,
    builder: (context) {
      return WnDialog.custom(
        customChild: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remove From Group?',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colors.primary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: WnImage(
                    AssetsPaths.icClose,
                    size: 24.w,
                    color: context.colors.mutedForeground,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Gap(16.h),
            Text.rich(
              TextSpan(
                text: 'Are you sure you want to remove ',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.mutedForeground,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
                children: [
                  TextSpan(
                    text: widget.member.displayName,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' from the group? They\'ll lose access to all messages and group activity. You\'ll need to invite them again if you want them back.',
                  ),
                ],
              ),
              textAlign: TextAlign.left,
            ),
            Gap(16.h),
            WnFilledButton(
              size: WnButtonSize.small,
              onPressed: () => Navigator.pop(context),
              visualState: WnButtonVisualState.secondary,
              label: 'Cancel',
            ),
            Gap(8.h),
            WnFilledButton(
              size: WnButtonSize.small,
              loading: _isRemoving,
              onPressed: _isRemoving ? null : _removeFromGroup,
              visualState: WnButtonVisualState.destructive,
              label: 'Remove From Group',
            ),
          ],
        ),
      );
    },
  );

  @override
  void initState() {
    super.initState();
    _loadCurrentUserNpub();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserIsAdmin =
        ref
            .watch(groupsProvider)
            .groupAdmins?[widget.groupId]
            ?.firstWhereOrNull(
              (admin) => admin.publicKey == currentUserNpub,
            ) !=
        null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Gap(16.h),
        WnAvatar(
          imageUrl: widget.member.imagePath ?? '',
          displayName: widget.member.displayName,
          size: 96.w,
        ),
        Gap(4.h),
        Text(
          widget.member.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.member.nip05.isNotEmpty)
          Text(
            widget.member.nip05,
            style: TextStyle(
              color: context.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        Gap(16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  widget.member.publicKey.formatPublicKey(),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.mutedForeground,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              Gap(8.w),
              InkWell(
                onTap: _copyToClipboard,
                child: WnImage(
                  AssetsPaths.icCopy,
                  size: 24.w,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
        ),
        Gap(32.h),
        if (currentUserIsAdmin)
          Column(
            children: [
              Row(
                spacing: 6.w,
                children: [
                  Flexible(
                    child: SendMessageButton(widget.member),
                  ),
                  Flexible(
                    child: AddToContactButton(widget.member),
                  ),
                ],
              ),
            ],
          )
        else
          SendMessageButton(widget.member),
        Gap(8.h),
        WnFilledButton(
          onPressed: _openAddToGroup,
          size: WnButtonSize.small,
          visualState: WnButtonVisualState.secondary,
          label: 'Add to Another Group',
          suffixIcon: WnImage(
            AssetsPaths.icChatInvite,
            width: 14.w,
            height: 13.h,
            color: context.colors.primary,
          ),
        ),
        if (currentUserIsAdmin) ...[
          Gap(8.h),
          WnFilledButton(
            onPressed: () async {
              final result = await _openRemoveFromGroupDialog();
              if (result == true && context.mounted) {
                Navigator.pop(context);
              }
            },
            size: WnButtonSize.small,
            visualState: WnButtonVisualState.secondaryWarning,
            label: 'Remove From Group',
            labelTextStyle: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.destructive,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
            suffixIcon: WnImage(
              AssetsPaths.icRemoveOutlined,
              width: 14.w,
              height: 13.h,
              color: context.colors.destructive,
            ),
          ),
        ] else ...[
          Gap(8.h),
          AddToContactButton(widget.member),
        ],
      ],
    );
  }
}
