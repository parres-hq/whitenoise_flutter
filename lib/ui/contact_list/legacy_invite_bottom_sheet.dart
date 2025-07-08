import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class LegacyInviteBottomSheet extends ConsumerStatefulWidget {
  final String name;
  final String nip05;
  final String? bio;
  final String? imagePath;
  final String pubkey;
  final VoidCallback? onInviteSent;
  const LegacyInviteBottomSheet({
    super.key,
    required this.name,
    required this.nip05,
    this.bio,
    this.imagePath,
    this.onInviteSent,
    required this.pubkey,
  });

  static Future<void> show({
    required BuildContext context,
    required String name,
    required String nip05,
    required String pubkey,
    String? bio,
    String? imagePath,
    VoidCallback? onInviteSent,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Invite to Chat',
      heightFactor: 0.75,
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder:
          (context) => LegacyInviteBottomSheet(
            name: name,
            nip05: nip05,
            bio: bio,
            imagePath: imagePath,
            onInviteSent: onInviteSent,
            pubkey: pubkey,
          ),
    );
  }

  @override
  ConsumerState<LegacyInviteBottomSheet> createState() => _LegacyInviteBottomSheetState();
}

class _LegacyInviteBottomSheetState extends ConsumerState<LegacyInviteBottomSheet> {
  final _logger = Logger('LeacyInviteBottomSheet');
  bool _isSendingInvite = false;

  Future<void> _legacyInvite() async {
    setState(() {
      _isSendingInvite = true;
    });
    try {
      final invited = await ref
          .read(chatProvider.notifier)
          .sendLegacyNip04Message(
            contactPubkey: widget.pubkey,
            message:
                'I\'d like to connect with you on White Noise. Download the app here: https://whitenoise.chat',
          );
      if (invited) {
        _logger.info('Invite sent successfully: ${widget.name} (${widget.pubkey})');

        if (mounted) {
          Navigator.pop(context);

          if (widget.onInviteSent != null) {
            widget.onInviteSent!();
          }

          ref.showSuccessToast('Invite sent successfully!');
        }
      } else {
        throw Exception('Failed to create direct message group');
      }
    } catch (e) {
      String errorMessage;
      if (e is WhitenoiseError) {
        errorMessage = await whitenoiseErrorToString(error: e);
      } else {
        errorMessage = e.toString();
      }
      if (mounted) {
        ref.showRawErrorToast('Failed to send Invite');

        _logger.severe('Failed to send invite: $errorMessage', e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingInvite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Gap(48.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(40.r),
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: context.colors.warning,
                    borderRadius: BorderRadius.circular(40.r),
                  ),
                  child:
                      widget.imagePath != null && widget.imagePath!.isNotEmpty
                          ? Image.network(
                            widget.imagePath!,
                            width: 80.w,
                            height: 80.w,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Center(
                                  child: Text(
                                    widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: context.colors.neutral,
                                      fontSize: 32.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                          )
                          : Center(
                            child: Text(
                              widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: context.colors.neutral,
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                ),
              ),
              Gap(12.h),
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w500,
                  color: context.colors.primary,
                ),
              ),
              Gap(12.h),
              Text(
                widget.nip05,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                ),
              ),
              Gap(12.h),
              Text(
                widget.pubkey.formatPublicKey(),
                textAlign: TextAlign.center,
              ),
              Gap(12.h),
              Gap(32.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                width: 1.sw,
                decoration: BoxDecoration(
                  border: Border.all(color: context.colors.primary),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CarbonIcons.information_filled,
                          color: context.colors.primary,
                          size: 18.w,
                        ),
                        Gap(8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invite with Legacy DM',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.primary,
                                ),
                              ),
                              Gap(8.h),
                              Text(
                                'This contact isn’t on MLS yet. We’ll deliver an invitation through Nostr’s original direct-message system.',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: context.colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Gap(48.h),
            ],
          ),
        ),
        AppFilledButton(
          onPressed: _isSendingInvite ? null : _legacyInvite,
          title: _isSendingInvite ? 'Sending invite...' : 'Invite to Chat',
        ),
      ],
    );
  }
}
