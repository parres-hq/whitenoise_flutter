import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/ui/auth_flow/auth_header.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/status_bar_utils.dart';

class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> {
  bool _isLoading = false;
  bool _didTriggerDelete = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeAccountProvider.future);
    });
  }

  Future<void> _onContinuePressed(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    // Wait for account data to be loaded and petname to be available
    // Keep loading until we have a displayName (petname)
    while (true) {
      final activeAccountState = await ref.read(activeAccountProvider.future);

      if (activeAccountState.metadata?.displayName != null &&
          activeAccountState.metadata!.displayName!.isNotEmpty) {
        break;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
    }

    if (!context.mounted) return;

    setState(() {
      _isLoading = false;
    });

    context.go('/onboarding/create-profile');
  }

  void _deleteJustCreatedAccount() {
    if (_didTriggerDelete) return;
    _didTriggerDelete = true;
    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.deleteAccountInBackground();
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarUtils.wrapWithAdaptiveIcons(
      context,
      PopScope(
        onPopInvokedWithResult: (didPop, result) => _deleteJustCreatedAccount(),
        child: Scaffold(
          backgroundColor: context.colors.neutral,
          appBar: const AuthAppBar(title: 'Beyond the Noise'),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0).w,
                child: Column(
                  children: [
                    Gap(48.h),
                    FeatureItem(
                      context: context,
                      imagePath: AssetsPaths.blueHoodie,
                      title: 'Privacy & Security',
                      subtitle:
                          'Keep your conversations private. Even in case of a breach, your messages remain secure.',
                    ),
                    FeatureItem(
                      context: context,
                      imagePath: AssetsPaths.purpleWoman,
                      title: 'Choose Identity',
                      subtitle:
                          'Chat without revealing your phone number or email. Choose your identity: real name, pseudonym, or anonymous.',
                    ),
                    FeatureItem(
                      context: context,
                      imagePath: AssetsPaths.greenBird,
                      title: 'Decentralized & Permissionless',
                      subtitle:
                          'No central authority controls your communication—no permissions needed, no censorship possible.',
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
              ).copyWith(bottom: 32.h),
              child: Consumer(
                builder: (context, ref, child) {
                  final activeAccountState = ref.watch(activeAccountProvider);
                  final isButtonDisabled = _isLoading || activeAccountState.isLoading;
                  return WnFilledButton(
                    loading: isButtonDisabled,
                    onPressed: isButtonDisabled ? null : () => _onContinuePressed(context),
                    label: 'Setup Profile',
                    suffixIcon: WnImage(
                      AssetsPaths.icArrowRight,
                      color: context.colors.primaryForeground,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  const FeatureItem({
    super.key,
    required this.context,
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  final BuildContext context;
  final String imagePath;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 36).w,
      child: Row(
        children: [
          WnImage(imagePath, width: 128.w, height: 128.w, fit: BoxFit.contain),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: context.colors.primary,
                  ),
                ),
                Gap(6.w),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6.w,
                    color: context.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
