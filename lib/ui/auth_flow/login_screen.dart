import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/shared/custom_icon_button.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/app_text_form_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _keyController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _onContinuePressed() async {
    final key = _keyController.text.trim();

    if (key.isEmpty) {
      ref.showErrorToast('Please enter your private key');
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.loginWithKey(key);

    if (!mounted) return;

    // Read the auth state AFTER the login attempt to get the updated state
    final authState = ref.read(authProvider);

    if (authState.isAuthenticated && authState.error == null) {
      context.go(Routes.chats);
    } else {
      ref.showErrorToast(authState.error ?? 'Login failed');
    }
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      _keyController.text = clipboardData.text!;
      if (mounted) {
        ref.showSuccessToast('Pasted from clipboard');
      }
    } else {
      if (mounted) {
        ref.showInfoToast('Nothing to paste from clipboard');
      }
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: context.colors.neutral,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24).w,
          child: Container(
            constraints: BoxConstraints(
              minHeight:
                  (MediaQuery.of(context).size.height) -
                  (MediaQuery.of(context).padding.top + MediaQuery.of(context).padding.bottom),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Gap(48.h),
                    Text(
                      'Login to White Noise',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w700,
                        color: context.colors.mutedForeground,
                        height: 1.0,
                      ),
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                    ),
                    Gap(79.5.h),
                    Image.asset(
                      AssetsPaths.login,
                      height: 320.h,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                    Gap(79.5.h),
                  ],
                ),
                Gap(16.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter Your Private Key',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    Gap(6.h),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextFormField(
                            hintText: 'nsec...',
                            type: FieldType.password,
                            controller: _keyController,
                          ),
                        ),
                        Gap(4.w),
                        Container(
                          height: 52.w,
                          width: 52.w,
                          decoration: BoxDecoration(
                            color: context.colors.avatarSurface,
                          ),
                          child: CustomIconButton(
                            iconPath: AssetsPaths.icPaste,
                            onTap: _pasteFromClipboard,
                            padding: 18.w,
                          ),
                        ),
                      ],
                    ),
                    Gap(16.h),
                    authState.isLoading
                        ? Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                        )
                        : Padding(
                          padding: EdgeInsets.zero,
                          child: AppFilledButton(
                            onPressed: _keyController.text.isEmpty ? null : _onContinuePressed,
                            title: 'Login',
                          ),
                        ),
                    Gap(16.h),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
