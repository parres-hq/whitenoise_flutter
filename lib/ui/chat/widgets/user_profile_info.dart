import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class ChatGroupAppbar extends ConsumerWidget {
  const ChatGroupAppbar({
    super.key,
    required this.groupId,
    this.onTap,
  });

  final String groupId;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchedGroupImagePath = ref.watch(
      groupsProvider.select((s) => s.groupImagePaths?[groupId]),
    );
    final watchedGroupDisplayName = ref.watch(
      groupsProvider.select((s) => s.groupDisplayNames?[groupId]),
    );

    final content = Row(
      children: [
        WnAvatar(
          imageUrl: watchedGroupImagePath ?? '',
          displayName: watchedGroupDisplayName ?? 'shared.unknownUser'.tr(),
          size: 36.r,
          showBorder: true,
        ),
        Gap(8.w),
        Text(
          watchedGroupDisplayName ?? 'shared.unknownUser'.tr(),
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.solidPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
