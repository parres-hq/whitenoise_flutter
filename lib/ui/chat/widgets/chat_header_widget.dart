import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/dm_chat_data.dart';
import 'package:whitenoise/domain/services/dm_chat_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class ChatContactHeader extends ConsumerWidget {
  final Group group;

  const ChatContactHeader({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGroupChat = group.groupType == GroupType.group;

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
  Future<String>? _groupNpubFuture;

  @override
  void initState() {
    super.initState();
    _groupNpubFuture = npubFromHexPubkey(hexPubkey: widget.group.nostrGroupId);
  }

  @override
  void didUpdateWidget(GroupChatHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.nostrGroupId != widget.group.nostrGroupId) {
      _groupNpubFuture = npubFromHexPubkey(hexPubkey: widget.group.nostrGroupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Gap(32.h),
          WnAvatar(
            imageUrl: '',
            displayName: widget.group.name,
            size: 96.r,
            showBorder: true,
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
          Gap(16.h),
          FutureBuilder(
            future: _groupNpubFuture,
            builder: (context, asyncSnapshot) {
              final groupNpub = asyncSnapshot.data ?? '';
              return Text(
                groupNpub.formatPublicKey(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                ),
              );
            },
          ),
          Gap(12.h),
          if (widget.group.description.isNotEmpty) ...[
            Text(
              'Group Description:',
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

class DirectMessageHeader extends ConsumerStatefulWidget {
  final Group group;

  const DirectMessageHeader({super.key, required this.group});

  @override
  ConsumerState<DirectMessageHeader> createState() => _DirectMessageHeaderState();
}

class _DirectMessageHeaderState extends ConsumerState<DirectMessageHeader> {
  Future<DMChatData?>? _dmChatDataFuture;

  @override
  void initState() {
    super.initState();
    _dmChatDataFuture = ref.getDMChatData(widget.group.mlsGroupId);
  }

  @override
  void didUpdateWidget(DirectMessageHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.mlsGroupId != widget.group.mlsGroupId) {
      _dmChatDataFuture = ref.getDMChatData(widget.group.mlsGroupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dmChatDataFuture,
      builder: (context, asyncSnapshot) {
        final otherUser = asyncSnapshot.data;
        if (otherUser == null) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Gap(32.h),
              WnAvatar(
                imageUrl: otherUser.displayImage ?? '',
                displayName: otherUser.displayName,
                size: 96.r,
                showBorder: true,
              ),
              Gap(12.h),
              Text(
                otherUser.displayName,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
              Gap(4.h),
              Text(
                otherUser.nip05 ?? '',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                ),
              ),
              Gap(12.h),
              Text(
                otherUser.publicKey?.formatPublicKey() ?? '',
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
      },
    );
  }
}

extension StringExtension on String? {
  bool get nullOrEmpty => this?.isEmpty ?? true;
  // Returns a default image path if the string is null or empty
  String get orDefault => (this == null || this!.isEmpty) ? AssetsPaths.icImage : this!;
  String get capitalizeFirst {
    if (this == null || this!.isEmpty) return '';
    return '${this![0].toUpperCase()}${this!.substring(1)}';
  }
}
