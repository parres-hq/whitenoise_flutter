import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/contact_list/widgets/share_invite_button.dart';
import 'package:whitenoise/ui/contact_list/widgets/share_invite_callout.dart';
import 'package:whitenoise/ui/contact_list/widgets/user_profile.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_callout.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

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
    return WnBottomSheet.show(
      context: context,
      title: 'ui.inviteToChat'.tr(),
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder: (context) => ShareInviteBottomSheet(contacts: contacts, onInviteSent: onInviteSent),
    );
  }

  @override
  ConsumerState<ShareInviteBottomSheet> createState() => _ShareInviteBottomSheetState();
}

class _ShareInviteBottomSheetState extends ConsumerState<ShareInviteBottomSheet> {
  @override
  Widget build(BuildContext context) {
    if (widget.contacts.isEmpty) {
      return const SizedBox.shrink();
    }
    final isSingleContact = widget.contacts.length == 1;
    final singleContact = widget.contacts.first;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSingleContact) ...[
          Gap(12.h),
          UserProfile(
            imageUrl: singleContact.imagePath ?? '',
            name: singleContact.displayName,
            nip05: singleContact.nip05 ?? '',
            pubkey: singleContact.publicKey,
            ref: ref,
          ),
          Gap(36.h),
          ShareInviteCallout(contact: singleContact),
        ] else ...[
          // Multiple contacts view
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                Gap(24.h),
                WnCallout(
                  title: 'ui.inviteToWhiteNoise'.tr(),
                  description: 'ui.contactsNotReadyForSecureMessaging'.tr(),
                ),
                Gap(16.h),
              ],
            ),
          ),

          ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            shrinkWrap: true,
            primary: false,
            itemCount: widget.contacts.length,
            itemBuilder: (context, index) {
              final contact = widget.contacts[index];
              return ContactListTile(contact: contact);
            },
          ),
        ],
        Gap(14.h),
        const ShareInviteButton(),
      ],
    );
  }
}
