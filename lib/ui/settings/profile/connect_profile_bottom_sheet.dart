import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';

class ConnectProfileBottomSheet extends ConsumerStatefulWidget {
  const ConnectProfileBottomSheet({super.key});

  static Future<void> show({
    required BuildContext context,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Connect Another Profile',
      showCloseButton: false,
      showBackButton: true,
      builder: (context) => const ConnectProfileBottomSheet(),
    );
  }

  @override
  ConsumerState<ConnectProfileBottomSheet> createState() => _ConnectProfileBottomSheetState();
}

class _ConnectProfileBottomSheetState extends ConsumerState<ConnectProfileBottomSheet> {
  bool _isLoginLoading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFilledButton(
          title: 'Login With Existing Profile',
          loading: _isLoginLoading,
          visualState: WnButtonVisualState.secondary,
          onPressed:
              authState.isLoading
                  ? null
                  : () async {
                    setState(() {
                      _isLoginLoading = true;
                    });

                    Navigator.pop(context);

                    // Go directly to login screen without logging out current account
                    // This preserves the current account and prevents previous accounts
                    // from being deleted when a new account is added
                    ref.read(authProvider.notifier).setUnAuthenticated();

                    if (context.mounted) {
                      context.go(Routes.login);
                    }
                  },
        ),
        Gap(4.h),
        AppFilledButton(
          title: 'Create New Profile',
          loading: authState.isLoading,
          onPressed: () async {
            // Wait for account creation and metadata generation
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
      ],
    );
  }
}
