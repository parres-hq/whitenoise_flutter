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

class _LoginScreenState extends ConsumerState<LoginScreen> with WidgetsBindingObserver {
  final TextEditingController _keyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _wasKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _keyController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _handleKeyboardVisibility();
  }

  void _handleKeyboardVisibility() {
    final keyboardVisible = View.of(context).viewInsets.bottom > 0;
    
    // Check if keyboard just became visible and text field has focus
    if (keyboardVisible && !_wasKeyboardVisible && _focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
    
    _wasKeyboardVisible = keyboardVisible;
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
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.colors.neutral,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24).w,
          controller: _scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 24.h),
                    child: Text(
                      'Login to White Noise',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w700,
                        color: context.colors.mutedForeground,
                      ),
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                    ),
                  ),
                  Gap(79.5.h),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        AssetsPaths.login,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  Gap(79.5.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
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
                              focusNode: _focusNode,
                            ),
                          ),
                          Gap(4.w),
                          Container(
                            height: 56.w,
                            width: 56.w,
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
                          : AppFilledButton(
                            onPressed: _keyController.text.isEmpty ? null : _onContinuePressed,
                            title: 'Login',
                          ),
                      Gap(16.h),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
