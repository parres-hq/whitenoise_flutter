import 'package:flutter/material.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/core/ui/wn_callout.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class ShareInviteCallout extends StatelessWidget {
  final ContactModel contact;

  const ShareInviteCallout({
    super.key,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    final contactName =
        contact.displayName.isNotEmpty && contact.displayName != 'Unknown User'
            ? contact.displayName
            : 'chats.thisUser'.tr();
    final inviteMessage = 'chats.userNotOnWhiteNoise'.tr({'contactName': contactName});

    return WnCallout(title: 'chats.inviteToWhiteNoise'.tr(), description: inviteMessage);
  }
}
