import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';
import 'package:whitenoise/config/constants.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';

class ShareInviteButton extends ConsumerStatefulWidget {
  const ShareInviteButton({
    super.key,
  });

  @override
  ConsumerState<ShareInviteButton> createState() => _ShareInviteButtonState();
}

class _ShareInviteButtonState extends ConsumerState<ShareInviteButton> {
  final _logger = Logger('ShareInviteButton');
  bool _isSendingInvite = false;

  Future<void> _shareInvite() async {
    setState(() {
      _isSendingInvite = true;
    });

    try {
      await Share.share(kInviteMessage);

      if (mounted) {
        Navigator.pop(context);
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
    return Column(
      children: [
        WnFilledButton(
          onPressed: _isSendingInvite ? null : _shareInvite,
          loading: _isSendingInvite,
          title: _isSendingInvite ? 'Sharing...' : 'Share',
        ),
      ],
    );
  }
}
