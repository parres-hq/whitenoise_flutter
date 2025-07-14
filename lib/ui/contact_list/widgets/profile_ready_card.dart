import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/providers/profile_ready_card_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/contact_list/new_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';

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
                child: Icon(
                  CarbonIcons.close,
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
          AppFilledButton.child(
            onPressed: () {
              context.push('${Routes.settings}/share_profile');
            },
            size: AppButtonSize.small,
            visualState: AppButtonVisualState.secondary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Share Your Profile',
                  style: AppButtonSize.small.textStyle().copyWith(
                    color: context.colors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(6.w),
                Icon(
                  CarbonIcons.qr_code,
                  size: 16.w,
                  color: context.colors.primary,
                ),
              ],
            ),
          ),
          Gap(12.h),
          // Search For Friends button
          AppFilledButton.child(
            onPressed: () {
              NewChatBottomSheet.show(context);
            },
            size: AppButtonSize.small,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Search For Friends',
                  style: AppButtonSize.small.textStyle().copyWith(
                    color: context.colors.primaryForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(6.w),
                Icon(
                  CarbonIcons.user_follow,
                  size: 16.w,
                  color: context.colors.primaryForeground,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
