import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/nostr_keys_provider.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/shared/custom_icon_button.dart';
import 'package:whitenoise/shared/info_box.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class NostrKeysScreen extends ConsumerStatefulWidget {
  const NostrKeysScreen({super.key});

  @override
  ConsumerState<NostrKeysScreen> createState() => _NostrKeysScreenState();
}

class _NostrKeysScreenState extends ConsumerState<NostrKeysScreen> {
  final TextEditingController _privateKeyController = TextEditingController();
  bool _obscurePrivateKey = true;

  @override
  void initState() {
    super.initState();

    // Load keys when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKeys();
    });
  }

  /// Load both public and private keys when the screen initializes
  Future<void> _loadKeys() async {
    final authState = ref.read(authProvider);

    if (authState.isAuthenticated) {
      try {
        // Get the active account data directly
        final activeAccountData =
            await ref.read(activeAccountProvider.notifier).getActiveAccountData();

        if (activeAccountData != null) {
          print('NostrKeysScreen: Found active account: ${activeAccountData.pubkey}');

          // Load keys directly using the new API
          final nostrKeys = ref.read(nostrKeysProvider);

          try {
            // Convert pubkey string to PublicKey object
            final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);

            // Load properly formatted npub
            final npubString = await exportAccountNpub(pubkey: publicKey);
            nostrKeys.loadPublicKeyFromAccountData(npubString);

            // Load private key
            final nsecString = await exportAccountNsec(pubkey: publicKey);
            nostrKeys.setNsec(nsecString);

            print('NostrKeysScreen: Keys loaded successfully with new API');
          } catch (e) {
            print('NostrKeysScreen: Error loading keys: $e');
            // Fallback to raw pubkey
            nostrKeys.loadPublicKeyFromAccountData(activeAccountData.pubkey);
          }
        } else {
          print('NostrKeysScreen: No active account found');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No active account found'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('NostrKeysScreen: Error loading keys: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading keys: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Update the text field when nsec changes
  void _updateTextField() {
    final nsec = ref.read(nostrKeysProvider).nsec;
    if (nsec != null && _privateKeyController.text != nsec) {
      _privateKeyController.text = nsec;
    }
  }

  void _copyPublicKey() {
    final npub = ref.read(nostrKeysProvider).npub;
    if (npub != null) {
      Clipboard.setData(ClipboardData(text: npub));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Public key copied to clipboard')),
      );
    }
  }

  void _copyPrivateKey() {
    final nsec = ref.read(nostrKeysProvider).nsec;
    if (nsec != null) {
      Clipboard.setData(ClipboardData(text: nsec));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Private key copied to clipboard')),
      );
    }
  }

  void _togglePrivateKeyVisibility() {
    setState(() {
      _obscurePrivateKey = !_obscurePrivateKey;
    });
  }

  @override
  void dispose() {
    // Clear the private key when navigating away for security
    ref.read(nostrKeysProvider).clearNsec();
    _privateKeyController.dispose();
    super.dispose();
  }

  /// Format public key for display by adding spaces for readability
  String _formatPublicKey(String key) {
    if (key.length <= 20) return key;

    // Add space every 5 characters for readability
    String formatted = '';
    for (int i = 0; i < key.length; i += 5) {
      if (i > 0) formatted += ' ';
      final end = (i + 5 < key.length) ? i + 5 : key.length;
      formatted += key.substring(i, end);
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the providers for reactive updates
    final nostrKeys = ref.watch(nostrKeysProvider);

    // Update text field when nsec is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTextField();
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'Nostr Keys'),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionWidget(
                title: 'Public Key',
                description:
                    'Your public key is your unique identifier in the Nostr network, enabling others to verify and recognize your messages. Share it openly!',
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28.r,
                      backgroundImage: const AssetImage(
                        AssetsPaths.profileBackground,
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child:
                          nostrKeys.npub != null
                              ? Text(
                                _formatPublicKey(nostrKeys.npub!),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.glitch600,
                                ),
                              )
                              : Text(
                                'Loading public key...',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.glitch400,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
              CustomFilledButton(
                buttonType: ButtonType.secondary,
                onPressed: nostrKeys.npub != null ? _copyPublicKey : null,
                title: 'Copy Public Key',
                addPadding: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      AssetsPaths.icCopy,
                      colorFilter:
                          nostrKeys.npub != null
                              ? null
                              : const ColorFilter.mode(
                                AppColors.glitch400,
                                BlendMode.srcIn,
                              ),
                    ),
                    Gap(8.w),
                    Text(
                      'Copy Public Key',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: nostrKeys.npub != null ? AppColors.glitch950 : AppColors.glitch400,
                      ),
                    ),
                  ],
                ),
              ),
              Gap(48.h),
              const SectionWidget(
                title: 'Private Key',
                description:
                    'Private key works like a secret password that grants access to your Nostr identity.',
              ),
              Gap(16.h),
              const InfoBox(
                colorTheme: AppColors.colorEA580C,
                title: 'Keep your private key safe!',
                description:
                    'Don\'t share your private key publicly, and use it only to log in to other Nostr apps.',
              ),
              Gap(16.h),

              // Show loading state or private key input
              if (nostrKeys.isLoading)
                SizedBox(
                  height: 50.h,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.glitch600,
                            ),
                          ),
                        ),
                        Gap(12.w),
                        Text(
                          'Loading private key...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.glitch600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (nostrKeys.error != null)
                SizedBox(
                  height: 50.h,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 20.r),
                        Gap(12.w),
                        Expanded(
                          child: Text(
                            'Error loading private key: ${nostrKeys.error}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        textController: _privateKeyController,
                        obscureText: _obscurePrivateKey,
                        readOnly: true,
                        padding: EdgeInsets.zero,
                      ),
                    ),
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

  const SectionWidget({
    required this.title,
    required this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 24.sp, color: AppColors.glitch900),
        ),
        Gap(8.h),
        Text(
          description,
          style: TextStyle(fontSize: 16.sp, color: AppColors.glitch600),
        ),
      ],
    );
  }
}
