import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/routing/chat_navigation_extension.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class SendMessageButton extends ConsumerStatefulWidget {
  const SendMessageButton(this.user, {super.key});
  final User user;

  @override
  ConsumerState<SendMessageButton> createState() => _SendMessageButtonState();
}

class _SendMessageButtonState extends ConsumerState<SendMessageButton> {
  final _logger = Logger('SendMessageButton');
  bool _isCreatingGroup = false;
  bool get _isLoading => _isCreatingGroup;

  Future<void> _createOrOpenDirectMessageGroup() async {
    if (widget.user.publicKey.isEmpty) {
      ref.showErrorToast('No user to start chat with');
      return;
    }
    setState(() {
      _isCreatingGroup = true;
    });

    try {
      final group = await ref
          .read(groupsProvider.notifier)
          .createNewGroup(
            groupName: 'DM',
            groupDescription: 'Direct message',
            memberPublicKeyHexs: [widget.user.publicKey],
            adminPublicKeyHexs: [widget.user.publicKey],
          );

      if (group != null) {
        _logger.info('Direct message group created successfully: ${group.mlsGroupId}');

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context);
              context.navigateToGroupChatAndPopToHome(group);
            }
          });

          ref.showSuccessToast(
            'Chat with ${widget.user.displayName} started successfully',
          );
        }
      } else {
        if (mounted) {
          final groupsState = ref.read(groupsProvider);
          final errorMessage = groupsState.error ?? 'Failed to create direct message group';
          ref.showErrorToast(errorMessage);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingGroup = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WnFilledButton(
      onPressed: _createOrOpenDirectMessageGroup,
      loading: _isLoading,
      size: WnButtonSize.small,
      visualState: WnButtonVisualState.secondary,
      label: 'Send Message',
      suffixIcon: WnImage(
        AssetsPaths.icMessage,
        width: 14.w,
        height: 13.h,
        color: context.colors.primary,
      ),
    );
  }
}

class AddToContactButton extends ConsumerStatefulWidget {
  const AddToContactButton(this.user, {super.key});
  final User user;

  @override
  ConsumerState<AddToContactButton> createState() => _AddToContactButtonState();
}

class _AddToContactButtonState extends ConsumerState<AddToContactButton> {
  bool _isAddingContact = false;
  bool get _isLoading => _isAddingContact;

  bool _isContact() {
    final followsState = ref.watch(followsProvider);
    final follows = followsState.follows;

    return follows.any(
      (follow) => follow.pubkey.toLowerCase() == widget.user.publicKey.toLowerCase(),
    );
  }

  Future<void> _toggleContact() async {
    setState(() {
      _isAddingContact = true;
    });

    try {
      final followsNotifier = ref.read(followsProvider.notifier);
      final isCurrentlyFollow = followsNotifier.isFollowing(widget.user.publicKey);

      if (isCurrentlyFollow) {
        await followsNotifier.removeFollow(widget.user.publicKey);
        if (mounted) {
          ref.showSuccessToast('${widget.user.displayName} removed from follows');
        }
      } else {
        await followsNotifier.addFollow(widget.user.publicKey);
        if (mounted) {
          ref.showSuccessToast('${widget.user.displayName} added to follows');
        }
      }
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to update follow: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingContact = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isContact = _isContact();
    return WnFilledButton(
      onPressed: _toggleContact,
      loading: _isLoading,
      size: WnButtonSize.small,
      visualState: WnButtonVisualState.secondary,
      label: isContact ? 'Remove Contact' : 'Add Contact',
      suffixIcon: WnImage(
        isContact ? AssetsPaths.icRemoveUser : AssetsPaths.icAddUser,
        size: 11.w,
        color: context.colors.primary,
      ),
    );
  }
}
