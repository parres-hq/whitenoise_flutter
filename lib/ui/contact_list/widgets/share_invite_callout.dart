import 'package:flutter/material.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/core/ui/wn_callout.dart';

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
            : 'This user';
    final inviteMessage =
        "$contactName isn't on White Noise yet. Share the download link to start a secure chat.";

    return WnCallout(title: 'Invite to White Noise', description: inviteMessage);
  }
}
