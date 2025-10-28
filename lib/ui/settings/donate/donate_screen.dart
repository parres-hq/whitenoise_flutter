import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/constants.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_icon_button.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/ui/core/widgets/wn_settings_screen_wrapper.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class DonateScreen extends ConsumerWidget {
  const DonateScreen({super.key});

  void _copyToClipboard(WidgetRef ref, String type, String text) {
    ClipboardUtils.copyWithToast(
      ref: ref,
      textToCopy: text,
      successMessage: 'donate.copiedAddressSuccess'.tr({'type': type}),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WnSettingsScreenWrapper(
      title: 'settings.donateToWhiteNoise'.tr(),
      safeAreaBottom: false,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    bottom: 24.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'donate.description'.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: context.colors.mutedForeground,
                          height: 1.4,
                        ),
                      ),
                      Gap(32.h),
                      Text(
                        'donate.lightningAddress'.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: context.colors.primary,
                        ),
                      ),
                      Gap(10.h),
                      Row(
                        children: [
                          Expanded(
                            child: WnTextFormField(
                              controller: TextEditingController(
                                text: kLightningAddress,
                              ),
                              readOnly: true,
                            ),
                          ),
                          Gap(4.w),
                          WnIconButton(
                            onTap: () => _copyToClipboard(ref, 'lightning', kLightningAddress),
                            iconPath: AssetsPaths.icCopy,
                            size: 56.h,
                            padding: 20.w,
                          ),
                        ],
                      ),
                      Gap(32.h),
                      Text(
                        'donate.bitcoinSilentPaymentAddress'.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: context.colors.primary,
                        ),
                      ),
                      Gap(10.h),
                      Row(
                        children: [
                          Expanded(
                            child: WnTextFormField(
                              controller: TextEditingController(
                                text: kBitcoinAddress,
                              ),
                              readOnly: true,
                            ),
                          ),
                          Gap(4.w),
                          WnIconButton(
                            onTap:
                                () => _copyToClipboard(
                                  ref,
                                  'bitcoin',
                                  kBitcoinAddress,
                                ),
                            iconPath: AssetsPaths.icCopy,
                            size: 56.h,
                            padding: 20.w,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
