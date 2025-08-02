import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/relays.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/contact_list/share_invite_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/start_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class ContactLoadingBottomSheet extends ConsumerStatefulWidget {
  final ContactModel contact;
  final ValueChanged<GroupData?>? onChatCreated;
  final VoidCallback? onInviteSent;

  const ContactLoadingBottomSheet({
    required this.contact,
    this.onChatCreated,
    this.onInviteSent,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required ContactModel contact,
    ValueChanged<GroupData?>? onChatCreated,
    VoidCallback? onInviteSent,
  }) {
    return WnBottomSheet.show(
      context: context,
      title: 'Connecting...',
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      barrierDismissible: false,
      builder:
          (context) => ContactLoadingBottomSheet(
            contact: contact,
            onChatCreated: onChatCreated,
            onInviteSent: onInviteSent,
          ),
    );
  }

  @override
  ConsumerState<ContactLoadingBottomSheet> createState() => _ContactLoadingBottomSheetState();
}

class _ContactLoadingBottomSheetState extends ConsumerState<ContactLoadingBottomSheet> {
  final _logger = Logger('ContactLoadingBottomSheet');
  bool _isCompleted = false;
  String _loadingMessage = 'Checking secure chat availability...';

  @override
  void initState() {
    super.initState();
    // Start fetching key package immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkKeyPackageAndNavigate();
    });
  }

  Future<Event?> _fetchKeyPackageWithRetry(String publicKeyString) async {
    const maxAttempts = 3;
    Event? lastSuccessfulResult;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _logger.info('Key package fetch attempt $attempt for $publicKeyString');

        // Create fresh PublicKey object for each attempt to avoid disposal issues
        final freshPubkey = await publicKeyFromString(publicKeyString: publicKeyString);
        final keyPackage = await fetchKeyPackage(pubkey: freshPubkey);

        _logger.info(
          'Key package fetch successful on attempt $attempt - result: ${keyPackage != null ? "found" : "null"}',
        );
        lastSuccessfulResult = keyPackage;
        return keyPackage; // Return immediately on success (whether null or not)
      } catch (e) {
        _logger.warning('Key package fetch attempt $attempt failed: $e');

        if (e.toString().contains('DroppableDisposedException')) {
          _logger.warning('Detected disposal exception, will retry with fresh objects');
        } else if (e.toString().contains('RustArc')) {
          _logger.warning('Detected RustArc error, will retry with fresh objects');
        } else {
          // For non-disposal errors, don't retry
          _logger.severe('Non-disposal error encountered, not retrying: $e');
          rethrow;
        }

        if (attempt == maxAttempts) {
          _logger.severe('Failed to fetch key package after $maxAttempts attempts: $e');
          throw Exception('Failed to fetch key package after $maxAttempts attempts: $e');
        }

        // Wait a bit before retry
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    // This should never be reached due to the logic above, but just in case
    return lastSuccessfulResult;
  }

  Future<void> _checkKeyPackageAndNavigate() async {
    if (_isCompleted) return;

    try {
      Event? keyPackage;

      try {
        // Update loading message
        if (mounted) {
          setState(() {
            _loadingMessage = 'Checking secure chat availability...';
          });
        }

        // Use retry mechanism for key package fetching
        keyPackage = await _fetchKeyPackageWithRetry(widget.contact.publicKey);
        _logger.info('Raw key package fetch result for ${widget.contact.publicKey}: $keyPackage');
        _logger.info('Key package is null: ${keyPackage == null}');
      } catch (e) {
        _logger.warning(
          'Failed to fetch key package for ${widget.contact.publicKey} after all retries: $e',
        );
        keyPackage = null;
      }

      // Mark as completed first to prevent multiple navigations
      if (mounted) {
        setState(() {
          _isCompleted = true;
          _loadingMessage = keyPackage != null ? 'Secure chat available!' : 'Preparing invite...';
        });

        // Short delay to show the completion message
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          _logger.info('=== Navigation Decision ===');
          _logger.info('keyPackage != null: ${keyPackage != null}');
          _logger.info(
            'Final decision: ${keyPackage != null ? "StartChatBottomSheet" : "ShareInviteBottomSheet"}',
          );

          // Close this loading sheet first
          Navigator.pop(context);

          // Navigate to the appropriate sheet
          if (keyPackage != null) {
            _logger.info('Showing StartChatBottomSheet for secure chat');
            await StartChatBottomSheet.show(
              context: context,
              name: widget.contact.displayName,
              nip05: widget.contact.nip05 ?? '',
              pubkey: widget.contact.publicKey,
              imagePath: widget.contact.imagePath,
              onChatCreated: widget.onChatCreated,
            );
          } else {
            _logger.info('Showing ShareInviteBottomSheet for sharing invite');
            await ShareInviteBottomSheet.show(
              context: context,
              contacts: [widget.contact],
              onInviteSent: widget.onInviteSent,
            );
          }
        }
      }
    } catch (e) {
      _logger.severe('Error checking key package: $e');

      if (mounted) {
        setState(() {
          _isCompleted = true;
          _loadingMessage = 'Connection failed. Preparing invite...';
        });

        // Short delay to show the error message, then navigate to invite sheet as fallback
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context);
          await ShareInviteBottomSheet.show(
            context: context,
            contacts: [widget.contact],
            onInviteSent: widget.onInviteSent,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Contact avatar
            ContactAvatar(
              imageUrl: widget.contact.imagePath ?? '',
              displayName: widget.contact.displayName,
              size: 80.r,
            ),
            Gap(16.h),

            // Contact name
            Text(
              widget.contact.displayName,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w500,
                color: context.colors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(8.h),

            // Contact public key (formatted)
            Text(
              widget.contact.publicKey.formatPublicKey(),
              style: TextStyle(
                fontSize: 12.sp,
                color: context.colors.mutedForeground,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
            Gap(32.h),

            // Loading indicator and message
            if (!_isCompleted) ...[
              SizedBox(
                width: 32.w,
                height: 32.w,
                child: CircularProgressIndicator(
                  strokeWidth: 3.0,
                  valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                ),
              ),
              Gap(16.h),
            ] else ...[
              Icon(
                Icons.check_circle,
                color: context.colors.primary,
                size: 32.w,
              ),
              Gap(16.h),
            ],

            Text(
              _loadingMessage,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}
