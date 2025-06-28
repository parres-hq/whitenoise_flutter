import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/profile_ready_card_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/contact_list/widgets/chat_list_appbar.dart';
import 'package:whitenoise/ui/contact_list/widgets/profile_ready_card.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityAsync = ref.watch(profileReadyCardVisibilityProvider);

    return Scaffold(
      appBar: ChatListAppBar(
        onSettingsTap: () => context.push(Routes.settings),
      ),
      body: ColoredBox(
        color: context.colors.neutral,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              'Welcome to White Noise. Private, secure,\ndecentralized, uncensorable messaging where your\nidentity stays yours.',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: visibilityAsync.when(
          data: (showCard) => showCard ? const ProfileReadyCard() : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
