import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class ChatUserHeader extends ConsumerWidget {
  final Group group;

  const ChatUserHeader({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupType = ref.watch(
      groupsProvider.select((s) => s.groupTypes?[group.mlsGroupId]),
    );
    if (groupType == null) {
      return const SizedBox.shrink();
    }

    final isGroupChat = groupType == GroupType.group;

    if (isGroupChat) {
      return GroupChatHeader(group: group);
    } else {
      return DirectMessageHeader(group: group);
    }
  }
}

class GroupChatHeader extends ConsumerStatefulWidget {
  final Group group;

  const GroupChatHeader({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<GroupChatHeader> createState() => _GroupChatHeaderState();
}

class _GroupChatHeaderState extends ConsumerState<GroupChatHeader> {
  @override
  Widget build(BuildContext context) {
    final cachedImagePath = ref.watch(
      groupsProvider.select((s) => s.groupImagePaths?[widget.group.mlsGroupId]),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Gap(32.h),
          WnAvatar(
            imageUrl: cachedImagePath ?? '',
            displayName: widget.group.name,
            size: 96.r,
            showBorder: true,
            pubkey: widget.group.nostrGroupId,
          ),
          Gap(12.h),
          Text(
            widget.group.name,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
          Gap(12.h),
          if (widget.group.description.isNotEmpty) ...[
            Text(
              'chats.groupDescription'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.mutedForeground,
              ),
            ),
            Gap(4.h),
            Text(
              widget.group.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.colors.primary,
              ),
            ),
          ],
          Gap(32.h),
        ],
      ),
    );
  }
}

class DirectMessageHeader extends ConsumerWidget {
  final Group group;

  const DirectMessageHeader({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsNotifier = ref.watch(groupsProvider.notifier);
    final otherMember = groupsNotifier.getOtherGroupMember(group.mlsGroupId);

    if (otherMember == null) {
      return const SizedBox.shrink();
    }
    final displayName = ref.watch(
      groupsProvider.select((s) => s.groupDisplayNames?[group.mlsGroupId]),
    );

    final cachedImagePath = ref.watch(
      groupsProvider.select((s) => s.groupImagePaths?[group.mlsGroupId]),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Gap(32.h),
          WnAvatar(
            imageUrl: cachedImagePath ?? '',
            displayName: displayName,
            size: 96.r,
            showBorder: true,
            pubkey: otherMember.publicKey,
          ),
          Gap(12.h),
          Text(
            displayName ?? 'shared.unknownUser'.tr(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
          Gap(4.h),
          Text(
            otherMember.nip05,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.colors.mutedForeground,
            ),
          ),
          Gap(12.h),
          Text(
            otherMember.publicKey.formatPublicKey(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: context.colors.mutedForeground,
            ),
          ),
          Gap(32.h),
        ],
      ),
    );
  }
}
