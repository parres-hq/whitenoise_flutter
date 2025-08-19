import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/shared/custom_icon_button.dart';
import 'package:whitenoise/ui/auth_flow/qr_scanner_bottom_sheet.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';

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

    // Use the regular login method that shows loading state
    await authNotifier.loginWithKey(key);

    final authState = ref.read(authProvider);

    if (authState.isAuthenticated && authState.error == null) {
      if (!mounted) return;
      context.go(Routes.chats);
    } else if (authState.error != null) {
      // Error is already shown by the auth provider via toast
      // No need to show additional error here
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

  Future<void> _scanQRCode() async {
    final scannedCode = await QRScannerBottomSheet.show(context);
    if (scannedCode != null && scannedCode.isNotEmpty) {
      _keyController.text = scannedCode;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.colors.neutral,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24).w,
          controller: _scrollController,
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height -
                (MediaQuery.of(context).padding.top + MediaQuery.of(context).padding.bottom),
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
                            child: WnTextFormField(
                              hintText: 'nsec...',
                              type: FieldType.password,
                              controller: _keyController,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                suffixIcon: GestureDetector(
                                  onTap: _scanQRCode,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.w),
                                    child: SvgPicture.asset(
                                      AssetsPaths.icScan,
                                      width: 16.w,
                                      height: 16.w,
                                      colorFilter: ColorFilter.mode(
                                        context.colors.primary,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Gap(4.w),
                          // Used .h for bothe to make it square and also go along with the 56.h
                          // calculation I made in WnTextFormField's vertical: 19.h.
                          // IntrinsicHeight avoided here since it's been used once in this page already.
                          // PS this has been tested on different screen sizes and it works fine.
                          Container(
                            height: 56.h,
                            width: 56.h,
                            decoration: BoxDecoration(
                              color: context.colors.avatarSurface,
                            ),
                            child: CustomIconButton(
                              iconPath: AssetsPaths.icPaste,
                              onTap: _pasteFromClipboard,
                              padding: 20.w,
                              size: 56.h,
                            ),
                          ),
                        ],
                      ),
                      Gap(16.h),
                      Consumer(
                        builder: (context, ref, child) {
                          final authState = ref.watch(authProvider);
                          return WnFilledButton(
                            loading: authState.isLoading,
                            onPressed: _keyController.text.isEmpty ? null : _onContinuePressed,
                            label: 'Login',
                          );
                        },
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
