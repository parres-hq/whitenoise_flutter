import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/shared/custom_icon_button.dart';
import 'package:whitenoise/shared/info_box.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

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
      appBar: const CustomAppBar(title: Text('Wallet')),
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
                          'Connect bitcoin lightning wallet to send and receive payments within White Noise.',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: context.colors.secondaryForeground,
                          ),
                        ),
                        Gap(24.h),
                        Text(
                          'Connection Secret',
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
                              child: CustomTextField(
                                textController: _connectionSecretController,
                                hintText: 'nostr+walletconnect://...',
                                padding: EdgeInsets.zero,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                ),
                              ),
                            ),
                            Gap(8.w),
                            CustomIconButton(
                              iconPath: AssetsPaths.icCopy,
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: _connectionSecretController.text,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Connection secret copied to clipboard',
                                    ),
                                  ),
                                );
                              },
                            ),
                            Gap(8.w),
                            CustomIconButton(
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
                      title: 'What wallet can I connect?',
                      description:
                          'You can connect any wallet that supports Nostr Wallet Connect. See full list of such wallets here.',
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
