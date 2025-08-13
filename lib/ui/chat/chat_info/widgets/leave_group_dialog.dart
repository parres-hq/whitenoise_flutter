import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';

class LeaveGroupDialog extends ConsumerStatefulWidget {
  const LeaveGroupDialog({
    required this.groupId,
    required this.memberNpub,
    this.newAdmins,
    super.key,
  });

  final String groupId;
  final String memberNpub;
  final List<String>? newAdmins;

  static Future<bool?> show(
    BuildContext context, {
    required String groupId,
    required String memberNpub,
    List<String>? newAdmins,
  }) async {
    return await showDialog<bool?>(
      context: context,
      builder: (context) {
        return LeaveGroupDialog(
          groupId: groupId,
          memberNpub: memberNpub,
        );
      },
    );
  }

  @override
  ConsumerState<LeaveGroupDialog> createState() => _ConfirmLeaveGroupDialogState();
}

class _ConfirmLeaveGroupDialogState extends ConsumerState<LeaveGroupDialog> {
  bool _isRemovingSelf = false;

  Future<void> _removeSelfFromGroup() async {
    final groupDetails = ref.read(groupsProvider).groupsMap?[widget.groupId];
    final groupName = groupDetails?.name != null ? 'The Group ${groupDetails!.name}' : 'The Group';
    setState(() {
      _isRemovingSelf = true;
    });

    try {
      if (widget.newAdmins != null && widget.newAdmins!.isNotEmpty) {
        // TODO : implement logic to add new admins when api is ready
        // await ref.read(groupsProvider.notifier).addGroupAdmins(
        //   groupId: widget.groupId,
        //   groupAdmins: widget.newAdmins!,
        // );
      }
      await ref
          .read(groupsProvider.notifier)
          .removeFromGroup(
            groupId: widget.groupId,
            membersNpubs: [widget.memberNpub],
          );
      if (mounted) {
        ref.showSuccessToast('Successfully left $groupName');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to leave group: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRemovingSelf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WnDialog.custom(
      customChild: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leave Group?',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colors.primary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(CarbonIcons.close),
                color: context.colors.mutedForeground,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Gap(16.h),
          Text(
            'Are you sure you want to leave this group? You won\'t be able to access it again unless someone re-invites you.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.mutedForeground,
              fontSize: 14.sp,
            ),
          ),
          Gap(16.h),
          WnFilledButton(
            size: WnButtonSize.small,
            onPressed: () => Navigator.pop(context, false),
            visualState: WnButtonVisualState.secondary,
            title: 'Cancel',
          ),
          Gap(8.h),
          WnFilledButton(
            size: WnButtonSize.small,
            onPressed: _removeSelfFromGroup,
            visualState: WnButtonVisualState.destructive,
            loading: _isRemovingSelf,
            title: 'Leave Group',
          ),
        ],
      ),
    );
  }
}

//
