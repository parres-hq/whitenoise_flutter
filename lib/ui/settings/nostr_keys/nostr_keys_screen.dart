import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/nostr_keys_provider.dart';
import 'package:whitenoise/shared/custom_icon_button.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class NostrKeysScreen extends ConsumerStatefulWidget {
  const NostrKeysScreen({super.key});

  @override
  ConsumerState<NostrKeysScreen> createState() => _NostrKeysScreenState();
}

class _NostrKeysScreenState extends ConsumerState<NostrKeysScreen> {
  final TextEditingController _privateKeyController = TextEditingController();
  bool _obscurePrivateKey = true;
  final _logger = Logger('NostrKeysScreen');

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
          _logger.info('NostrKeysScreen: Found active account: ${activeAccountData.pubkey}');

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

            _logger.info('NostrKeysScreen: Keys loaded successfully with new API');
          } catch (e) {
            _logger.severe('NostrKeysScreen: Error loading keys: $e');
            // Fallback to raw pubkey
            nostrKeys.loadPublicKeyFromAccountData(activeAccountData.pubkey);
          }
        } else {
          _logger.severe('NostrKeysScreen: No active account found');
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
        _logger.severe('NostrKeysScreen: Error loading keys: $e');
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
      backgroundColor: context.colors.neutral,
      appBar: const CustomAppBar(title: Text('Profile Keys')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Public Key Section
              Text(
                'Public Key',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.secondaryForeground,
                ),
              ),
              Gap(16.h),

              // Public Key Input Field
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colors.input,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        child: nostrKeys.npub != null
                            ? Text(
                              _formatPublicKey(nostrKeys.npub!),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: context.colors.secondaryForeground,
                                fontFamily: 'monospace',
                              ),
                            )
                            : Text(
                              'Loading public key...',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: context.colors.baseMuted,
                              ),
                            ),
                      ),
                    ),
                  ),
                  Gap(8.w),
                  CustomIconButton(
                    onTap: _copyPublicKey,
                    iconPath: AssetsPaths.icCopy,
                  ),
                ],
              ),
              Gap(12.h),

              // Public Key Description
              Text(
                'Your public key is your unique identifier in the Nostr network, enabling others to verify and recognize your messages. Share it openly!',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                  height: 1.4,
                ),
              ),

              Gap(32.h),

              // Private Key Section
              Text(
                'Private Key',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.secondaryForeground,
                ),
              ),
              Gap(16.h),

              // Show loading state or private key input
              if (nostrKeys.isLoading)
                Container(
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: context.colors.input,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.colors.mutedForeground,
                            ),
                          ),
                        ),
                        Gap(12.w),
                        Text(
                          'Loading private key...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: context.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (nostrKeys.error != null)
                Container(
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: context.colors.input,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error,
                          color: context.colors.destructive,
                          size: 20.r,
                        ),
                        Gap(12.w),
                        Expanded(
                          child: Text(
                            'Error loading private key: ${nostrKeys.error}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: context.colors.destructive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Private Key Input Field
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colors.input,
                        ),
                        child: CustomTextField(
                          textController: _privateKeyController,
                          obscureText: _obscurePrivateKey,
                          readOnly: true,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                      ),
                    ),
                    Gap(8.w),
                    CustomIconButton(
                      onTap: _togglePrivateKeyVisibility,
                      iconPath: AssetsPaths.icView,
                    ),
                    Gap(8.w),
                    CustomIconButton(
                      onTap: _copyPrivateKey,
                      iconPath: AssetsPaths.icCopy,
                    ),
                  ],
                ),
              Gap(12.h),

              // Private Key Description
              Text(
                'Private key works like a secret password that grants access to your Nostr identity.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                  height: 1.4,
                ),
              ),
              Gap(24.h),

              // Custom Warning Box
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: context.colors.destructive.withValues(alpha: 0.1),
                  border: Border.all(
                    color: context.colors.destructive,
                    width: 1.w,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 4.w),
                      child: Icon(
                        Icons.warning,
                        size: 16.w,
                        color: context.colors.destructive,
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keep your private key safe!',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: context.colors.secondaryForeground,
                            ),
                          ),
                          Gap(8.h),
                          Text(
                            'Don\'t share your private key publicly, and use it only to log in to other Nostr apps.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: context.colors.secondaryForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
