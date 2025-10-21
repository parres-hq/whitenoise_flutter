import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class QRScannerBottomSheet extends ConsumerStatefulWidget {
  const QRScannerBottomSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return WnBottomSheet.show<String>(
      context: context,
      title: 'auth.scanQrCode'.tr(),
      showBackButton: true,
      showCloseButton: false,
      builder: (context) => const QRScannerBottomSheet(),
    );
  }

  @override
  ConsumerState<QRScannerBottomSheet> createState() => _QRScannerBottomSheetState();
}

class _QRScannerBottomSheetState extends ConsumerState<QRScannerBottomSheet> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  String? _lastInvalidKey;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final scannedValue = barcode.rawValue!.trim();

        if (!scannedValue.startsWith('nsec')) {
          if (_lastInvalidKey != scannedValue) {
            _lastInvalidKey = scannedValue;
            _resetTimer?.cancel();
            _resetTimer = Timer(const Duration(seconds: 5), () {
              if (mounted) {
                _lastInvalidKey = null;
              }
            });
            ref.showErrorToast('auth.invalidPrivateKeyFormat'.tr());
            return;
          }
          return;
        }

        _lastInvalidKey = null;
        _resetTimer?.cancel();

        setState(() {
          _isScanning = false;
        });
        Navigator.of(context).pop(scannedValue);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Code Scanner Area
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: SizedBox(
            height: 300.h,
            width: double.infinity,
            child:
                _isScanning
                    ? MobileScanner(
                      controller: cameraController,
                      onDetect: _onDetect,
                    )
                    : Container(
                      color: context.colors.baseMuted,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            WnImage(
                              AssetsPaths.icCheckmarkFilledSvg,
                              size: 94.w,
                              color: context.colors.primary,
                            ),
                            Gap(16.h),
                            Text(
                              'auth.qrCodeDetected'.tr(),
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: context.colors.primaryForeground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ),
        Gap(24.h),
        Text(
          'auth.scanYourPrivateKeyQr'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            color: context.colors.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
