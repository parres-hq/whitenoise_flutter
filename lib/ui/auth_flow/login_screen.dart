import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/app_icon_button.dart';
import 'package:whitenoise/ui/core/ui/app_text_form_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _keyController = TextEditingController();

  Future<void> _onContinuePressed() async {
    final key = _keyController.text.trim();

    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your private key')),
      );
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);
    final authState = ref.read(authProvider);
    await authNotifier.loginWithKey(key);

    if (!mounted) return;

    if (authState.isAuthenticated && authState.error == null) {
      context.go(Routes.chats);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authState.error ?? 'Login failed')),
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      _keyController.text = clipboardData.text!;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pasted from clipboard')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to paste from clipboard')),
        );
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
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Image.asset(
                    AssetsPaths.hands,
                    height: 320.h,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      'Login to White Noise',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w500,
                        color: context.colors.textDefaultSecondary,
                        height: 1.0,
                      ),
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Text(
                'Enter Your Private Key',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  color: context.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(
                    child: AppTextFormField(
                      hintText: 'nsec...',
                      type: FieldType.password,
                      controller: _keyController,
                    ),
                  ),
                  SizedBox(width: 8.h),
                  AppIconButton(
                    onPressed: _pasteFromClipboard,
                    hasBorder: true,
                    icon: Icons.paste,
                    size: 52.w,
                  ),
                ],
              ),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child:
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                  ).copyWith(bottom: 32.h),
                  child: AppFilledButton(
                    onPressed: _onContinuePressed,
                    title: 'Login',
                  ),
                ),
      ),
    );
  }
}
