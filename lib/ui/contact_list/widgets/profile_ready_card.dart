import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/profile_ready_card_provider.dart';
import 'package:whitenoise/ui/contact_list/new_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
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
          Text(
            'Your Profile is Ready',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
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

          Row(
            children: [
              Expanded(
                child: AppFilledButton(
                  onPressed: () {
                    ref.read(profileReadyCardVisibilityProvider.notifier).dismissCard();
                  },
                  title: 'Dismiss',
                  size: AppButtonSize.small,
                  visualState: AppButtonVisualState.secondary,
                ),
              ),
              Gap(8.w),
              Expanded(
                child: AppFilledButton.child(
                  onPressed: () {
                    ref.read(profileReadyCardVisibilityProvider.notifier).dismissCard();

                    NewChatBottomSheet.show(context);
                  },
                  size: AppButtonSize.small,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Start Chatting',
                          style: AppButtonSize.small.textStyle(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Gap(6.w),
                      SvgPicture.asset(
                        AssetsPaths.icStartChatting,
                        width: 12.w,
                        height: 12.w,
                        colorFilter: ColorFilter.mode(
                          context.colors.primaryForeground,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
