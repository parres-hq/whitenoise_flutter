import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class LegacyInviteBottomSheet extends ConsumerStatefulWidget {
  final List<ContactModel> contacts;
  final VoidCallback? onInviteSent;
  const LegacyInviteBottomSheet({
    super.key,
    required this.contacts,
    this.onInviteSent,
  });

  static Future<void> show({
    required BuildContext context,
    required List<ContactModel> contacts,
    VoidCallback? onInviteSent,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Invite to Chat',
      heightFactor: 0.8,
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder:
          (context) => LegacyInviteBottomSheet(
            contacts: contacts,
            onInviteSent: onInviteSent,
          ),
    );
  }

  @override
  ConsumerState<LegacyInviteBottomSheet> createState() => _LegacyInviteBottomSheetState();
}

class _LegacyInviteBottomSheetState extends ConsumerState<LegacyInviteBottomSheet> {
  final _logger = Logger('LegacyInviteBottomSheet');
  bool _isSendingInvite = false;

  Future<void> _legacyInvite() async {
    setState(() {
      _isSendingInvite = true;
    });

    try {
      int successCount = 0;
      int failureCount = 0;

      for (final contact in widget.contacts) {
        try {
          final invited = await ref
              .read(chatProvider.notifier)
              .sendLegacyNip04Message(
                contactPubkey: contact.publicKey,
                message:
                    'I\'d love to chat securely and keep our conversations private. White Noise offers fully encrypted, ad-free, tracker-free communication, built for privacy from the ground up. Join me here: https://whitenoise.chat',
              );

          if (invited) {
            successCount++;
            _logger.info('Invite sent successfully: ${contact.name} (${contact.publicKey})');
          } else {
            failureCount++;
          }
        } catch (e) {
          failureCount++;
          _logger.severe('Failed to send invite to ${contact.name}: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context);

        if (widget.onInviteSent != null) {
          widget.onInviteSent!();
        }

        // Show result toast
        if (successCount > 0 && failureCount == 0) {
          ref.showSuccessToast(
            widget.contacts.length > 1
                ? 'All invites sent successfully!'
                : 'Invite sent successfully!',
          );
        } else if (successCount > 0 && failureCount > 0) {
          ref.showSuccessToast('$successCount invites sent, $failureCount failed');
        } else {
          ref.showErrorToast('Failed to send invites');
        }
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
    final isSingleContact = widget.contacts.length == 1;
    final contact = isSingleContact ? widget.contacts.first : null;

    return Column(
      children: [
        if (isSingleContact) ...[
          // Single contact view
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
                        contact!.imagePath != null && contact.imagePath!.isNotEmpty
                            ? Image.network(
                              contact.imagePath!,
                              width: 80.w,
                              height: 80.w,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Center(
                                    child: Text(
                                      contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
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
                                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
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
                  contact.name,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.primary,
                  ),
                ),
                Gap(12.h),
                Text(
                  contact.nip05 ?? '',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.colors.mutedForeground,
                  ),
                ),
                Gap(12.h),
                Text(
                  contact.publicKey.formatPublicKey(),
                  textAlign: TextAlign.center,
                ),
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
                                  'This contact isn\'t ready for secure messaging yet. Invite them to download White Noise?',
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
              ],
            ),
          ),
        ] else ...[
          // Multiple contacts view
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                Gap(24.h),
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
                                  'These contacts aren\'t ready for secure messaging yet. Invite them to download White Noise?.',
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
                Gap(16.h),
              ],
            ),
          ),
          // Contacts list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              itemCount: widget.contacts.length,
              itemBuilder: (context, index) {
                final contact = widget.contacts[index];
                return ContactListTile(contact: contact);
              },
            ),
          ),
        ],
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w).copyWith(bottom: 16.h),
            child: AppFilledButton(
              onPressed: _isSendingInvite ? null : _legacyInvite,
              title: _isSendingInvite ? 'Sending invite...' : 'Invite to Chat',
            ),
          ),
        ),
      ],
    );
  }
}
