import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/info_box.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_icon_button.dart';
import 'package:whitenoise/ui/core/ui/wn_text_field.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final TextEditingController _connectionSecretController = TextEditingController();

  @override
  void dispose() {
    _connectionSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral,
      appBar: WnAppBar(title: Text('ui.wallet'.tr())),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Gap(24.h),
                        Text(
                          'wallet.connectionDescription'.tr(),
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: context.colors.secondaryForeground,
                          ),
                        ),
                        Gap(24.h),
                        Text(
                          'wallet.connectionString'.tr(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: context.colors.secondaryForeground,
                          ),
                        ),
                        Gap(8.h),
                        Row(
                          children: [
                            Expanded(
                              child: WnTextField(
                                textController: _connectionSecretController,
                                hintText: 'nostr+walletconnect://...',
                                padding: EdgeInsets.zero,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                ),
                              ),
                            ),
                            Gap(8.w),
                            WnIconButton(
                              iconPath: AssetsPaths.icCopy,
                              onTap: () {
                                ClipboardUtils.copyWithToast(
                                  ref: ref,
                                  textToCopy: _connectionSecretController.text,
                                  successMessage: 'wallet.connectionStringCopied'.tr(),
                                );
                              },
                            ),
                            Gap(8.w),
                            WnIconButton(
                              iconPath: AssetsPaths.icScan,
                              onTap: () {
                                // QR code scanner functionality
                              },
                            ),
                          ],
                        ),
                        Gap(52.h),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: InfoBox(
                      colorTheme: context.colors.secondaryForeground,
                      title: 'wallet.informationQuestion'.tr(),
                      description: 'wallet.informationAnswer'.tr(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
