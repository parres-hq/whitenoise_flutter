import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/error.dart';
import 'package:whitenoise/src/rust/api/users.dart' as wn_users_api;
import 'package:whitenoise/ui/contact_list/start_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/public_key_validation_extension.dart';

class ShareProfileQrScanScreen extends ConsumerStatefulWidget {
  const ShareProfileQrScanScreen({super.key, this.hideViewQrButton = false});

  final bool hideViewQrButton;

  @override
  ConsumerState<ShareProfileQrScanScreen> createState() => _ShareProfileQrScanScreenState();
}

class _ShareProfileQrScanScreenState extends ConsumerState<ShareProfileQrScanScreen>
    with WidgetsBindingObserver {
  final Logger logger = Logger('ShareProfileQrScanScreen');
  String npub = '';
  late MobileScannerController _controller;
  StreamSubscription<BarcodeCapture>? _subscription;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
    );
    WidgetsBinding.instance.addObserver(this);
    _subscription = _controller.barcodes.listen(_handleBarcode);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.colors.appBarBackground,
        body: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: context.colors.neutral,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Gap(24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Row(
                    children: [
                      const BackButton(),
                      Expanded(
                        child: Text(
                          'Scan QR Code',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: context.colors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Spacer(),
                                  Center(
                                    child: AspectRatio(
                                      aspectRatio: 1.0,
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth: 288.w,
                                          maxHeight: 288.w,
                                          minWidth: 200.w,
                                          minHeight: 200.w,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: context.colors.primary,
                                            width: 1.w,
                                          ),
                                        ),
                                        child: MobileScanner(controller: _controller),
                                      ),
                                    ),
                                  ),
                                  Gap(16.h),
                                  Text(
                                    'Scan user\'s QR code to connect.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.mutedForeground,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!widget.hideViewQrButton) ...[
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                                      child: WnFilledButton(
                                        label: 'View QR Code',
                                        onPressed: () => context.pop(),
                                        suffixIcon: WnImage(
                                          AssetsPaths.icQrCode,
                                          size: 18.w,
                                          color: context.colors.primaryForeground,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 64.h),
                                  ] else ...[
                                    SizedBox(height: 64.h),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _subscription = _controller.barcodes.listen(_handleBarcode);
        unawaited(_controller.start());
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(_controller.stop());
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty) return;

    try {
      final barcode = capture.barcodes.first;
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        final npub = barcode.rawValue!;
        if (!npub.isValidPublicKey) {
          ref.showWarningToast('Invalid public key format');
          _controller.stop();
          _delayedCameraRestart();
          return;
        }
        _controller.stop();
        final user = await wn_users_api.getUser(pubkey: npub);
        final contact = ContactModel.fromUser(user: user);
        if (mounted) {
          await StartChatBottomSheet.show(
            context: context,
            contact: contact,
            onChatCreated: (group) {
              if (group != null && mounted) {
                // Navigate to home first, then to the group chat
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.go(Routes.home);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Routes.goToChat(context, group.mlsGroupId);
                      }
                    });
                  }
                });
              }
            },
          );
        }
      }
    } catch (e) {
      String? errorMessage = 'Something went wrong';
      _controller.stop();
      if (e is ApiError) {
        errorMessage = await e.messageText();
      }
      logger.severe(errorMessage, e);
      ref.showErrorToast(errorMessage);
    } finally {
      _delayedCameraRestart();
    }
  }

  void _delayedCameraRestart() => Future.delayed(const Duration(seconds: 4), () {
    if (mounted) {
      _controller.start();
    }
  });
}
