import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/constants.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_icon_button.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';

class DonateScreen extends ConsumerWidget {
  const DonateScreen({super.key});

  void _copyToClipboard(WidgetRef ref, String text) {
    ClipboardUtils.copyWithToast(
      ref: ref,
      textToCopy: text,
      successMessage: 'Copied address to clipboard',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
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
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 16.w,
                        right: 16.w,
                        bottom: 24.w,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Gap(24.h),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: SvgPicture.asset(
                                  AssetsPaths.icChevronLeft,
                                  width: 24.w,
                                  height: 24.w,
                                  colorFilter: ColorFilter.mode(
                                    context.colors.primary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              Gap(16.w),
                              Text(
                                'Donate to White Noise',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                          Gap(32.h),
                          Text(
                            'As a not-for-profit, White Noise exists solely for your privacy and freedom, not for profit. Your support keeps us independent and uncompromised.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: context.colors.mutedForeground,
                              height: 1.4,
                            ),
                          ),
                          Gap(32.h),
                          Text(
                            'Lightning Address',
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
                                onTap: () => _copyToClipboard(ref, kLightningAddress),
                                iconPath: AssetsPaths.icCopy,
                                size: 56.h,
                                padding: 20.w,
                              ),
                            ],
                          ),
                          Gap(32.h),
                          Text(
                            'Bitcoin Silent Payment Address',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
