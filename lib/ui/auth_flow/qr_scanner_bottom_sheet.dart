import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class QRScannerBottomSheet extends StatefulWidget {
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
  State<QRScannerBottomSheet> createState() => _QRScannerBottomSheetState();
}

class _QRScannerBottomSheetState extends State<QRScannerBottomSheet> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isScanning = false;
        });
        Navigator.of(context).pop(barcode.rawValue);
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
        Container(
          height: 300.h,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 2.0,
            ),
          ),
          child: _isScanning
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
