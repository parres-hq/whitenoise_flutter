import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/constants.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class ShareInviteBottomSheet extends ConsumerStatefulWidget {
  final List<ContactModel> contacts;
  final VoidCallback? onInviteSent;
  const ShareInviteBottomSheet({
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
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder:
          (context) => ShareInviteBottomSheet(
            contacts: contacts,
            onInviteSent: onInviteSent,
          ),
    );
  }

  @override
  ConsumerState<ShareInviteBottomSheet> createState() => _ShareInviteBottomSheetState();
}

class _ShareInviteBottomSheetState extends ConsumerState<ShareInviteBottomSheet> {
  final _logger = Logger('ShareInviteBottomSheet');
  bool _isSendingInvite = false;

  Future<void> _shareInvite() async {
    setState(() {
      _isSendingInvite = true;
    });

    try {
      await Share.share(kInviteMessage);

      if (mounted) {
        Navigator.pop(context);

        if (widget.onInviteSent != null) {
          widget.onInviteSent!();
        }

        // Show success toast
        ref.showSuccessToast('Invite shared successfully!');
      }
    } catch (e) {
      _logger.severe('Failed to share invite: $e');
      if (mounted) {
        ref.showErrorToast('Failed to share invite');
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
    if (contact == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSingleContact) ...[
          // Single contact view
          Column(
            children: [
              Gap(12.h),
              ContactAvatar(
                imageUrl: contact.imagePath ?? '',
                displayName: contact.displayNameOrName,
                size: 96.r,
              ),
              Gap(8.h),
              Text(
                contact.displayNameOrName,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
              if (contact.nip05 != null && contact.nip05!.isNotEmpty) ...[
                Gap(2.h),
                Text(
                  contact.nip05!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.colors.mutedForeground,
                  ),
                ),
              ],
              Gap(16.h),
              Text(
                contact.publicKey.formatPublicKey(),
                textAlign: TextAlign.center,
              ),
              Gap(40.h),
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
                                'Invite to White Noise',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.primary,
                                ),
                              ),
                              Gap(8.h),
                              Text(
                                "${contact.name.isNotEmpty && contact.name != 'Unknown User' ? contact.name : 'This user'} isn't on White Noise yet. Share the download link to start a secure chat.",
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
                                  'Invite to White Noise',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.primary,
                                  ),
                                ),
                                Gap(8.h),
                                Text(
                                  'These contacts aren\'t ready for secure messaging yet. Share White Noise with them to get started!',
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
        Gap(40.h),
        AppFilledButton(
          onPressed: _isSendingInvite ? null : _shareInvite,
          loading: _isSendingInvite,
          title: _isSendingInvite ? 'Sharing...' : 'Share',
        ),
      ],
    );
  }
}
