import 'package:flutter/material.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/ui/core/ui/wn_callout.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class ShareInviteCallout extends StatelessWidget {
  final UserProfile userProfile;

  const ShareInviteCallout({
    super.key,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final userName =
        userProfile.displayName.isNotEmpty && userProfile.displayName != 'shared.unknownUser'.tr()
            ? userProfile.displayName
            : 'chats.thisUser'.tr();
    final inviteMessage = 'chats.userNotOnWhiteNoise'.tr({'userName': userName});

    return WnCallout(title: 'chats.inviteToWhiteNoise'.tr(), description: inviteMessage);
  }
}
