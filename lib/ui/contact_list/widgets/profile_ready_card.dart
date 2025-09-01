import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/profile_ready_card_visibility_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/contact_list/new_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class ProfileReadyCard extends ConsumerWidget {
  const ProfileReadyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityAsync = ref.watch(profileReadyCardVisibilityProvider);

    return visibilityAsync.when(
      data: (isVisible) {
        if (!isVisible) {
          return const SizedBox.shrink();
        }

        return _buildCard(context, ref);
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.w),
      margin: EdgeInsets.symmetric(horizontal: 16.w).copyWith(bottom: 32.h),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Profile is Ready',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(profileReadyCardVisibilityProvider.notifier).dismissCard();
                },
                child: WnImage(
                  AssetsPaths.icClose,
                  size: 20.w,
                  color: context.colors.mutedForeground,
                ),
              ),
            ],
          ),
          Gap(8.h),
          Text(
            'Tap Start Chatting to search for contacts now, or use the + chat icon in the top-right corner whenever you like.',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: context.colors.mutedForeground,
            ),
          ),
          Gap(24.h),
          // Share Your Profile button
          WnFilledButton(
            label: 'Share Your Profile',
            onPressed: () => context.push('${Routes.settings}/share_profile'),
            size: WnButtonSize.small,
            visualState: WnButtonVisualState.secondary,
            suffixIcon: WnImage(
              AssetsPaths.icQrCode,

              color: context.colors.primary,
            ),
          ),
          Gap(12.h),
          // Search For Friends button
          WnFilledButton(
            label: 'Search For Friends',
            onPressed: () {
              // Dismiss the card when user takes action to search for friends
              ref.read(profileReadyCardVisibilityProvider.notifier).dismissCard();
              NewChatBottomSheet.show(context);
            },
            size: WnButtonSize.small,
            suffixIcon: WnImage(
              AssetsPaths.icAddUser,
              color: context.colors.primaryForeground,
            ),
          ),
        ],
      ),
    );
  }
}
