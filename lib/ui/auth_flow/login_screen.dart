import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/domain/services/nip55_callback.dart';
import 'package:whitenoise/domain/services/nip55_service.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/nip55.dart' as nip55_core_api;
import 'package:whitenoise/src/rust/api/nip55_extensions.dart' as nip55_api;
import 'package:whitenoise/ui/auth_flow/auth_header.dart';
import 'package:whitenoise/ui/auth_flow/qr_scanner_screen.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_icon_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';
import 'package:whitenoise/utils/public_key_validation_extension.dart';
import 'package:whitenoise/utils/status_bar_utils.dart';

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
  bool _isExternalSignerAvailable = false;
  static final Logger _logger = Logger('LoginScreen');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _keyController.addListener(() {
      setState(() {});
    });
    _checkExternalSigner();
  }

  Future<void> _checkExternalSigner() async {
    if (Platform.isAndroid) {
      try {
        final available = await Nip55Service.isExternalSignerInstalled();
        if (mounted) {
          setState(() {
            _isExternalSignerAvailable = available;
          });
        }
      } catch (e) {
        _logger.warning('Failed to check external signer: $e');
      }
    }
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
      Future.delayed(const Duration(milliseconds: 500), () {
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
      ref.showErrorToast('auth.pleaseEnterPrivateKey'.tr());
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

  Future<void> _loginWithExternalSigner() async {
    if (!mounted) {
      _logger.warning('Component not mounted, aborting NIP55 login');
      return;
    }

    try {
      _logger.info('Starting NIP55 login flow');

      _logger.fine('Ensuring NIP-55 callback is initialized');
      await Nip55CallbackInitializer.initialize();
      _logger.fine('NIP-55 callback initialized successfully');

      if (!mounted) {
        _logger.warning('Component not mounted after callback init, aborting');
        return;
      }

      _logger.info('Calling login_with_nip55 API');
      final account = await nip55_api.loginWithNip55();
      _logger.info('NIP55 API call completed. Account: ${account.pubkey}');

      if (!mounted) {
        _logger.warning('Component not mounted after API call, aborting');
        return;
      }

      if (!mounted) return;

      _logger.fine('Setting active pubkey');
      await ref.read(activePubkeyProvider.notifier).setActivePubkey(account.pubkey);

      if (!mounted) {
        _logger.fine('Component not mounted after setting pubkey');
        return;
      }

      _logger.info('Enabling NIP55 signer for pubkey: ${account.pubkey}');
      try {
        await nip55_core_api.enableNip55Signer(pubkey: account.pubkey);
        _logger.info('NIP55 signer enabled successfully');
      } catch (e, st) {
        _logger.severe('Failed to enable NIP-55 signer for account ${account.pubkey}', e, st);
        if (mounted) {
          ref.showErrorToast(
            'Failed to enable external signer. Please try again.',
          );
        }
        return; // Abort login flow if signer setup fails
      }

      _logger.fine('Refreshing active account provider');
      ref.invalidate(activeAccountProvider);
      final accountState = await ref.read(activeAccountProvider.future);
      _logger.fine('Account state loaded. Account exists: ${accountState.account != null}');

      if (!mounted) {
        _logger.fine('Component not mounted after account refresh');
        return;
      }

      _logger.info('Updating auth state to authenticated');
      ref.read(authProvider.notifier).setAuthenticated();

      final currentAuthState = ref.read(authProvider);
      _logger.fine(
        'Auth state after update: isAuthenticated=${currentAuthState.isAuthenticated}, isLoading=${currentAuthState.isLoading}',
      );

      if (!mounted) {
        _logger.fine('Component not mounted after auth update');
        return;
      }

      _logger.info('Navigating to chats screen');
      context.go(Routes.chats);
      _logger.info('NIP55 login flow completed successfully');
    } catch (e, st) {
      _logger.severe('NIP55 login flow failed', e, st);
      final errorMessage = e.toString();

      // Check if this is a relay setup error - account might still be created
      if (errorMessage.contains('relay not found') || errorMessage.contains('Relay not found')) {
        _logger.warning(
          'Relay setup failed during login, but account may have been created. Error: $e',
          e,
          st,
        );

        // Try to recover: get the pubkey from signer and set it as active
        // The account was likely created, just relay setup failed
        try {
          _logger.info('Attempting recovery: getting pubkey from signer');
          final resultJson = await Nip55Service.callNip55Method(
            method: 'get_public_key',
            params: '{}',
          );

          final result = jsonDecode(resultJson) as Map<String, dynamic>;
          final pubkeyNpub = result['result'] as String?;

          if (pubkeyNpub != null && pubkeyNpub.isValidNpubPublicKey) {
            // Convert npub to hex
            final hexPubkey = PubkeyFormatter(pubkey: pubkeyNpub).toHex();
            if (hexPubkey != null && mounted) {
              _logger.info('Recovery successful: setting active pubkey to $hexPubkey');
              await ref.read(activePubkeyProvider.notifier).setActivePubkey(hexPubkey);

              _logger.info('Recovery: Enabling NIP55 signer for pubkey: $hexPubkey');
              try {
                await nip55_core_api.enableNip55Signer(pubkey: hexPubkey);
                _logger.info('Recovery: NIP55 signer enabled successfully');
              } catch (e, st) {
                _logger.severe(
                  'Failed to enable NIP-55 signer during recovery for $hexPubkey',
                  e,
                  st,
                );
                if (mounted) {
                  ref.showErrorToast(
                    'Failed to enable external signer. Please try again.',
                  );
                }
                return; // Abort recovery flow if signer setup fails
              }

              // Refresh account state
              ref.invalidate(activeAccountProvider);
              await ref.read(activeAccountProvider.future);

              // Mark authenticated even if relay setup failed. Without this, GoRouter redirects
              // back to the login flow until app restart.
              ref.read(authProvider.notifier).setAuthenticated();

              ref.showWarningToast(
                'Login successful, but relay setup failed. Please add relays in settings.',
              );

              if (mounted) {
                context.go(Routes.chats);
              }
              return; // Successfully recovered
            }
          }
        } catch (recoveryError) {
          _logger.warning('Recovery attempt failed: $recoveryError');
        }

        // If recovery failed, show error
        if (mounted) {
          ref.showErrorToast(
            'Account created but relay setup failed. Please add relays in settings and try logging in again.',
          );
        }
        return; // Don't show generic error toast
      }

      if (mounted) {
        if (errorMessage.contains('not available') || errorMessage.contains('rebuild')) {
          // Log the original error for developers while showing user-friendly message
          _logger.severe(
            'NIP55 signer not available or requires rebuild. Original error: $e',
            e,
            st,
          );
          ref.showErrorToast(
            'An internal error occurred while attempting to sign in. Please try again or contact support.',
          );
        } else {
          _logger.severe('Login with external signer failed: $e', e, st);
          ref.showErrorToast('Failed to login with external signer: $e');
        }
      } else {
        _logger.severe('Login with external signer failed: $e', e, st);
      }
    }
  }

  Future<void> _scanQRCode() async {
    final scannedCode = await QRScannerScreen.navigate(context);
    if (scannedCode != null && scannedCode.isNotEmpty) {
      _keyController.text = scannedCode;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);

    return StatusBarUtils.wrapWithAdaptiveIcons(
      context: context,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: context.colors.neutral,
        appBar: AuthAppBar(title: 'auth.loginToWhiteNoise'.tr()),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24).w,
            controller: _scrollController,
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height -
                  (MediaQuery.of(context).padding.top +
                      MediaQuery.of(context).padding.bottom +
                      56.h),
              child: Column(
                children: [
                  const Spacer(),
                  Center(
                    child: WnImage(
                      AssetsPaths.login,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: 345.h,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'auth.enterYourPrivateKey'.tr(),
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
                                    child: WnImage(
                                      AssetsPaths.icScan,
                                      size: 16.w,
                                      color: context.colors.primary,
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
                            child: WnIconButton(
                              iconPath: AssetsPaths.icPaste,
                              onTap:
                                  () async => await ClipboardUtils.pasteWithToast(
                                    ref: ref,
                                    onPaste: (text) {
                                      _keyController.text = text;
                                    },
                                  ),
                              padding: 20.w,
                              size: 56.h,
                            ),
                          ),
                        ],
                      ),
                      Gap(8.h),
                      Consumer(
                        builder: (context, ref, child) {
                          final authState = ref.watch(authProvider);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              WnFilledButton(
                                loading: authState.isLoading,
                                onPressed: _keyController.text.isEmpty ? null : _onContinuePressed,
                                label: 'auth.login'.tr(),
                              ),
                              if (_isExternalSignerAvailable) ...[
                                Gap(16.h),
                                WnFilledButton(
                                  visualState: WnButtonVisualState.secondary,
                                  onPressed: _loginWithExternalSigner,
                                  label: 'nostrKeys.useExternalSigner'.tr(),
                                ),
                              ],
                            ],
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
