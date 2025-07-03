import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/nostr_keys_provider.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class ChatContactHeader extends ConsumerWidget {
  final GroupData groupData;

  const ChatContactHeader({super.key, required this.groupData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGroupChat = groupData.groupType == GroupType.group;

    if (isGroupChat) {
      return GroupChatHeader(groupData: groupData);
    } else {
      return DirectMessageHeader(groupData: groupData);
    }
  }
}

class GroupChatHeader extends ConsumerWidget {
  final GroupData groupData;

  const GroupChatHeader({
    super.key,
    required this.groupData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admins = ref.read(groupsProvider.notifier).getGroupAdmins(groupData.mlsGroupId) ?? [];
    final npub = ref.read(nostrKeysProvider).npub;
    // For now, we just take the first admin as the creator
    // This logic can be improved later to show the actual creator
    final firstAdmin = admins.isNotEmpty ? admins.first : null;
    final isCurrentUserAdmin = firstAdmin?.publicKey == npub;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Gap(32.h),
          ContactAvatar(
            imageUrl: '',
            displayName: groupData.name,
            size: 96.r,
            showBorder: true,
          ),
          Gap(12.h),
          Text(
            groupData.name,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
          Gap(16.h),
          Text(
            'nbup${groupData.nostrGroupId}'.formatPublicKey(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.colors.mutedForeground,
            ),
          ),
          Gap(12.h),
          if (groupData.description.isNotEmpty) ...[
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
              groupData.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.colors.primary,
              ),
            ),
            Gap(16.h),
          ],
          if (firstAdmin != null) ...[
            Text.rich(
              TextSpan(
                text: 'Group Chat Started by ',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                ),
                children: [
                  TextSpan(
                    text: isCurrentUserAdmin ? 'You' : firstAdmin.name.capitalizeFirst,
                    style: TextStyle(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
  final GroupData groupData;

  const DirectMessageHeader({super.key, required this.groupData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(activeAccountProvider)?.toNpub(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final npubKey = snapshot.data!;
        final otherUser = ref
            .read(groupsProvider.notifier)
            .getFirstOtherMember(groupData.mlsGroupId, npubKey);
        if (otherUser == null) return const SizedBox.shrink();
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Gap(32.h),
              ContactAvatar(
                imageUrl: '',
                displayName: otherUser.name,
                size: 96.r,
                showBorder: true,
              ),
              Gap(12.h),
              Text(
                otherUser.name.capitalizeFirst,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
              Gap(4.h),
              Text(
                otherUser.nip05,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                ),
              ),
              Gap(12.h),
              Text(
                otherUser.publicKey.formatPublicKey(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.colors.mutedForeground,
                ),
              ),
              Gap(32.h),
              Text.rich(
                TextSpan(
                  text: 'Chat started by ',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.colors.mutedForeground,
                  ),
                  children: [
                    TextSpan(
                      text: 'You',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
