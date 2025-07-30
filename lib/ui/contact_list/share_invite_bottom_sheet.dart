import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';
import 'package:whitenoise/config/constants.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/contact_list/widgets/user_profile.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_callout.dart';

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
    final title = contacts.length == 1 ? 'User Profile' : 'Invite to Chat';

    return WnBottomSheet.show(
      context: context,
      title: title,
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder: (context) => ShareInviteBottomSheet(contacts: contacts, onInviteSent: onInviteSent),
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
              UserProfile(
                imageUrl: contact.imagePath ?? '',
                name: contact.displayNameOrName,
                nip05: contact.nip05 ?? '',
                pubkey: contact.publicKey,
                ref: ref,
              ),
              Gap(36.h),
              WnCallout(
                title: 'Invite to White Noise',
                description:
                    "${(contact.displayName?.isNotEmpty ?? false) && contact.displayName != 'Unknown User' ? contact.displayName : 'This user'} isn't on White Noise yet. Share the download link to start a secure chat.",
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
                const WnCallout(
                  title: 'Invite to White Noise',
                  description:
                      "These contacts aren't ready for secure messaging yet. Share White Noise with them to get started!",
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
        Gap(10.h),
        WnFilledButton(
          onPressed: _isSendingInvite ? null : _shareInvite,
          loading: _isSendingInvite,
          title: _isSendingInvite ? 'Sharing...' : 'Share',
        ),
      ],
    );
  }
}
