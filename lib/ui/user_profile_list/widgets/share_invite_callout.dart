import 'package:flutter/material.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/ui/core/ui/wn_callout.dart';

class ShareInviteCallout extends StatelessWidget {
  final UserProfile userProfile;

  const ShareInviteCallout({
    super.key,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final userProfileName =
        userProfile.displayName.isNotEmpty && userProfile.displayName != 'Unknown User'
            ? userProfile.displayName
            : 'This user';
    final inviteMessage =
        "$userProfileName isn't on White Noise yet. Share the download link to start a secure chat.";

    return WnCallout(title: 'Invite to White Noise', description: inviteMessage);
  }
}
