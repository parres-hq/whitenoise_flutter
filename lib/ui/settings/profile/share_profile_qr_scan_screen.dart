import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/contact_list/start_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/utils/public_key_validation_extension.dart';

class ShareProfileQrScanScreen extends ConsumerStatefulWidget {
  const ShareProfileQrScanScreen({super.key});

  @override
  ConsumerState<ShareProfileQrScanScreen> createState() => _ShareProfileQrScanScreenState();
}

class _ShareProfileQrScanScreenState extends ConsumerState<ShareProfileQrScanScreen>
    with WidgetsBindingObserver {
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Gap(24.h),
                  Row(
                    children: [
                      const BackButton(),
                      Text(
                        'Scan QR Code',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: context.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 288.w,
                    height: 288.w,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.colors.primary,
                        width: 1.w,
                      ),
                    ),
                    child: MobileScanner(controller: _controller),
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
                  AppFilledButton.icon(
                    label: SvgPicture.asset(
                      AssetsPaths.icQrCode,
                      colorFilter: ColorFilter.mode(
                        context.colors.primaryForeground,
                        BlendMode.srcIn,
                      ),
                    ),
                    icon: Text(
                      'View QR Code',
                      style: TextStyle(
                        color: context.colors.primaryForeground,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => context.pop(),
                  ),
                  Gap(64.h),
                ],
              ),
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

    final barcode = capture.barcodes.first;
    if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
      final npub = barcode.rawValue!;
      if (!npub.isValidPublicKey) {
        ref.showWarningToast('Invalid public key format');
        _controller.stop();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _controller.start();
          }
        });
        return;
      }
      _controller.stop();
      final contact = await ref.read(metadataCacheProvider.notifier).getContactModel(npub);
      if (mounted) {
        await StartSecureChatBottomSheet.show(
          context: context,
          name: contact.name,
          nip05: contact.nip05 ?? '',
          pubkey: npub,
          onChatCreated: (groupData) {
            if (groupData != null && mounted) {
              // Navigate to home first, then to the group chat
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.go(Routes.home);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Routes.goToChat(context, groupData.mlsGroupId);
                    }
                  });
                }
              });
            }
          },
        );
      }
      _controller.start();
    }
  }
}
