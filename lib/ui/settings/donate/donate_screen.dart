import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/constants.dart';
import 'package:whitenoise/shared/custom_icon_button.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_text_form_field.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';

class DonateScreen extends ConsumerWidget {
  const DonateScreen({super.key});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
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
                                child: Icon(
                                  CarbonIcons.chevron_left,
                                  size: 24.w,
                                  color: context.colors.primary,
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
                                child: AppTextFormField(
                                  controller: TextEditingController(
                                    text: kLightningAddress,
                                  ),
                                  readOnly: true,
                                ),
                              ),
                              Gap(8.w),
                              CustomIconButton(
                                onTap: () => _copyToClipboard(context, kLightningAddress),
                                iconPath: AssetsPaths.icCopy,
                                size: 56.w,
                                padding: 20.w,
                              ),
                            ],
                          ),
                          Gap(12.h),
                          AppFilledButton.child(
                            onPressed: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Donate',
                                  style: WnButtonSize.large.textStyle().copyWith(
                                    color: context.colors.primaryForeground,
                                  ),
                                ),
                                Gap(8.w),
                                Icon(
                                  CarbonIcons.flash,
                                  size: 20.w,
                                  color: context.colors.primaryForeground,
                                ),
                              ],
                            ),
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
                                child: AppTextFormField(
                                  controller: TextEditingController(
                                    text: kBitcoinAddress,
                                  ),
                                  readOnly: true,
                                ),
                              ),
                              Gap(8.w),
                              CustomIconButton(
                                onTap:
                                    () => _copyToClipboard(
                                      context,
                                      kBitcoinAddress,
                                    ),
                                iconPath: AssetsPaths.icCopy,
                                size: 56.w,
                                padding: 20.w,
                              ),
                            ],
                          ),
                          Gap(12.h),
                          AppFilledButton.child(
                            onPressed: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Donate',
                                  style: WnButtonSize.large.textStyle().copyWith(
                                    color: context.colors.primaryForeground,
                                  ),
                                ),
                                Gap(8.w),
                                SvgPicture.asset(
                                  AssetsPaths.icBitcoin,
                                  height: 20.w,
                                  width: 20.w,
                                  colorFilter: ColorFilter.mode(
                                    context.colors.primaryForeground,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ],
                            ),
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
