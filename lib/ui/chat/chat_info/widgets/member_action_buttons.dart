import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/follow_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/routing/chat_navigation_extension.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

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
      ref.showErrorToast('chats.noUserToStartChatWith'.tr());
      return;
    }
    setState(() {
      _isCreatingGroup = true;
    });

    try {
      final group = await ref
          .read(groupsProvider.notifier)
          .createNewGroup(
            groupName: '',
            groupDescription: '',
            isDm: true,
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
            'ui.chatStartedSuccessfully'.tr({'name': widget.user.displayName}),
          );
        }
      } else {
        if (mounted) {
          final groupsState = ref.read(groupsProvider);
          final errorMessage = groupsState.error ?? 'ui.failedToCreateDirectMessageGroup'.tr();
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
      label: 'ui.sendMessage'.tr(),
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
  Future<void> _toggleFollow() async {
    final followNotifier = ref.read(followProvider(widget.user.publicKey).notifier);
    var currentFollowState = ref.read(followProvider(widget.user.publicKey));
    late String successMessage;

    if (currentFollowState.isFollowing) {
      successMessage = 'ui.unfollowed'.tr({'name': widget.user.displayName});
      await followNotifier.removeFollow(widget.user.publicKey);
    } else {
      successMessage = 'ui.followed'.tr({'name': widget.user.displayName});
      await followNotifier.addFollow(widget.user.publicKey);
    }

    currentFollowState = ref.read(followProvider(widget.user.publicKey));
    final errorMessage = currentFollowState.error ?? '';
    if (errorMessage.isNotEmpty) {
      ref.showErrorToast(errorMessage);
    } else {
      ref.showSuccessToast(successMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final followState = ref.watch(followProvider(widget.user.publicKey));

    return WnFilledButton(
      onPressed: followState.isLoading ? null : _toggleFollow,
      loading: followState.isLoading,
      size: WnButtonSize.small,
      visualState: WnButtonVisualState.secondary,
      label: followState.isFollowing ? 'ui.unfollow'.tr() : 'ui.follow'.tr(),
      suffixIcon: WnImage(
        followState.isFollowing ? AssetsPaths.icRemoveUser : AssetsPaths.icAddUser,
        size: 11.w,
        color: context.colors.primary,
      ),
    );
  }
}
