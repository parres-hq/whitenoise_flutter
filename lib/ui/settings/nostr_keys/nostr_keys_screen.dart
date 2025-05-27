import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/shared/custom_icon_button.dart';
import 'package:whitenoise/shared/info_box.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';
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
              CustomFilledButton(
                buttonType: ButtonType.secondary,
                onPressed: _copyPublicKey,
                title: 'Copy Public Key',
                addPadding: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(AssetsPaths.icCopy),
                    Gap(8.w),
                    Text(
                      'Copy Public Key',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.glitch950,
                      ),
                    ),
                  ],
                ),
              ),
              Gap(48.h),
              SectionWidget(
                title: 'Private Key',
                description: 'Private key works like a secret password that grants access to your Nostr identity.',
              ),
              Gap(16.h),
              InfoBox(
                colorTheme: AppColors.colorEA580C,
                title: 'Keep your private key safe!',
                description: 'Don\'t share your private key publicly, and use it only to log in to other Nostr apps.',
              ),
              Gap(16.h),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(obscureText: _obscurePrivateKey, readOnly: true, padding: EdgeInsets.zero),
                  ),
                  Gap(8.w),
                  CustomIconButton(onTap: _copyPrivateKey, iconPath: AssetsPaths.icCopy),
                  Gap(8.w),
                  CustomIconButton(onTap: _togglePrivateKeyVisibility, iconPath: AssetsPaths.icView),
                ],
              ),
              Gap(48.h),
              SectionWidget(
                title: 'Remove Nostr Keys',
                description: 'This will permanently erase this profile Nostr keys from White Noise.',
              ),
              Gap(16.h),
              CustomFilledButton(
                onPressed: _removeNostrKeys,
                buttonType: ButtonType.tertiary,
                addPadding: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(AssetsPaths.icDelete),
                    Gap(8.w),
                    Text(
                      'Remove Nostr Keys',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.glitch50,
                      ),
                    ),
                  ],
                ),
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
