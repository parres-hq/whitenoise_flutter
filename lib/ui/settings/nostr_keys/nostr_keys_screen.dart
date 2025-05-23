import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/shared/custom_icon_button.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';
import 'package:whitenoise/ui/settings/nostr_keys/remove_nostr_keys_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class NostrKeysScreen extends StatefulWidget {
  const NostrKeysScreen({super.key});

  @override
  State<NostrKeysScreen> createState() => _NostrKeysScreenState();
}

class _NostrKeysScreenState extends State<NostrKeysScreen> {
  final TextEditingController _privateKeyController = TextEditingController();
  bool _obscurePrivateKey = true;
  final String _publicKey = 'npub1 klkk3 vrzme 455yh 9rl2j shq7r c8dpe gj3nd f82c3 ks2sk 7qulx 40dxt 3vt';

  void _copyPublicKey() {
    Clipboard.setData(ClipboardData(text: _publicKey.replaceAll(' ', '')));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Public key copied to clipboard')));
  }

  void _copyPrivateKey() {
    Clipboard.setData(ClipboardData(text: _privateKeyController.text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Private key copied to clipboard')));
  }

  void _togglePrivateKeyVisibility() {
    setState(() {
      _obscurePrivateKey = !_obscurePrivateKey;
    });
  }

  void _removeNostrKeys() {
    RemoveNostrKeysBottomSheet.show(
      context: context,
      onRemove: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nostr keys removed')));
      },
    );
  }

  @override
  void dispose() {
    _privateKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: 'Nostr Keys'),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SectionWidget(
                title: 'Public Key',
                description:
                    'Your public key is your unique identifier in the Nostr network, enabling others to verify and recognize your messages. Share it openly!',
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Row(
                  children: [
                    CircleAvatar(radius: 28.r, backgroundImage: AssetImage(AssetsPaths.profileBackground)),
                    Gap(12.w),
                    Expanded(child: Text(_publicKey, style: TextStyle(fontSize: 14.sp, color: AppColors.glitch600))),
                  ],
                ),
              ),
              SettingsButton(title: 'Copy Public Key', iconPath: AssetsPaths.icCopy, onTap: _copyPublicKey),
              Gap(48.h),
              SectionWidget(
                title: 'Private Key',
                description: 'Private key works like a secret password that grants access to your Nostr identity.',
              ),
              Gap(16.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(color: const Color(0xFFEA580C).withValues(alpha: 0.1)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 4.w),
                      child: SvgPicture.asset(
                        AssetsPaths.icWarning,
                        width: 16.w,
                        height: 16.w,
                        colorFilter: ColorFilter.mode(Color(0xFFEA580C), BlendMode.srcIn),
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Keep your private key safe!',
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Color(0xFFEA580C)),
                          ),
                          Gap(8.h),
                          Text(
                            'Don\'t share your private key publicly, and use it only to log in to other Nostr apps.',
                            style: TextStyle(fontSize: 14.sp, color: Color(0xFFEA580C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Gap(16.h),
              Row(
                children: [
                  Expanded(child: CustomTextField(obscureText: _obscurePrivateKey, readOnly: true)),
                  Gap(8.w),
                  CustomIconButton(
                    onTap: _copyPrivateKey,
                    iconPath: AssetsPaths.icCopy,
                  ),
                  Gap(8.w),
                  CustomIconButton(
                    onTap: _togglePrivateKeyVisibility,
                    iconPath: AssetsPaths.icView,
                  ),
                ],
              ),
              Gap(48.h),
              SectionWidget(
                title: 'Remove Nostr Keys',
                description: 'This will permanently erase this profile Nostr keys from White Noise.',
              ),
              Gap(16.h),
              SettingsButton(
                title: 'Remove Nostr Keys',
                iconPath: AssetsPaths.icDelete,
                onTap: _removeNostrKeys,
                buttonColor: AppColors.colorDC2626,
                titleColor: AppColors.white,
              ),
              Gap(48.h),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionWidget extends StatelessWidget {
  final String title;
  final String description;

  const SectionWidget({required this.title, required this.description, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 24.sp, color: AppColors.glitch900)),
        Gap(8.h),
        Text(description, style: TextStyle(fontSize: 16.sp, color: AppColors.glitch600)),
      ],
    );
  }
}

class SettingsButton extends StatelessWidget {
  final String title;
  final String iconPath;
  final void Function()? onTap;
  final Color? buttonColor;
  final Color? titleColor;

  const SettingsButton({
    required this.title,
    required this.iconPath,
    required this.onTap,
    this.buttonColor,
    this.titleColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(color: buttonColor ?? AppColors.glitch100),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 16.w,
              height: 16.w,
              colorFilter: ColorFilter.mode(titleColor ?? AppColors.glitch950, BlendMode.srcIn),
            ),
            Gap(8.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: titleColor ?? AppColors.glitch950,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
