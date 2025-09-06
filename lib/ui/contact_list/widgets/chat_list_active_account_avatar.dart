import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';

class ChatListActiveAccountAvatar extends ConsumerWidget {
  const ChatListActiveAccountAvatar({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAccountState = ref.watch(activeAccountProvider);
    final metadata = activeAccountState.value?.metadata;
    final currentDisplayName = metadata?.displayName ?? '';
    final profileImagePath = metadata?.picture ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap:
          onTap ??
          () {
            context.push(Routes.settings);
          },
      child: WnAvatar(
        imageUrl: profileImagePath,
        displayName: currentDisplayName,
        size: 36.r,
      ),
    );
  }
}
