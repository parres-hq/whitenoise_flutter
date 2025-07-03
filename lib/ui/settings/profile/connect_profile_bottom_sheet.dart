import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';

class ConnectProfileBottomSheet extends ConsumerWidget {
  const ConnectProfileBottomSheet({super.key});

  static Future<void> show({
    required BuildContext context,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Connect Another Profile',
      showCloseButton: false,
      showBackButton: true,
      wrapContent: true,
      builder: (context) => const ConnectProfileBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFilledButton(
            title: 'Login With Existing Profile',
            visualState: AppButtonVisualState.secondary,
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).setUnAuthenticated();
              context.go(Routes.login);
            },
          ),
          Gap(4.h),
          AppFilledButton(
            title: 'Create New Profile',
            onPressed: () async {
              await ref.read(authProvider.notifier).createAccount();
              final authState = ref.read(authProvider);

              if (authState.isAuthenticated && authState.error == null) {
                if (!context.mounted) return;
                context.go(Routes.createProfile);
              } else {
                if (!context.mounted) return;
                ref.showErrorToast(authState.error ?? 'Unknown error');
              }
            },
          ),
          Gap(16.h),
        ],
      ),
    );
  }
}
