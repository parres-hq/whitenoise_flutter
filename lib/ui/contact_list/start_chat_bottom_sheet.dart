import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class StartSecureChatBottomSheet extends ConsumerStatefulWidget {
  final String name;
  final String nip05;
  final String? bio;
  final String? imagePath;
  final String pubkey;
  final VoidCallback? onStartChat;
  final ValueChanged<GroupData?>? onChatCreated;
  const StartSecureChatBottomSheet({
    super.key,
    required this.name,
    required this.nip05,
    this.bio,
    this.imagePath,
    this.onStartChat,
    this.onChatCreated,
    required this.pubkey,
  });

  static Future<void> show({
    required BuildContext context,
    required String name,
    required String nip05,
    required String pubkey,
    String? bio,
    String? imagePath,
    VoidCallback? onStartChat,
    ValueChanged<GroupData?>? onChatCreated,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Start Secure Chat',
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder:
          (context) => StartSecureChatBottomSheet(
            name: name,
            nip05: nip05,
            bio: bio,
            imagePath: imagePath,
            onStartChat: onStartChat,
            onChatCreated: onChatCreated,
            pubkey: pubkey,
          ),
    );
  }

  @override
  ConsumerState<StartSecureChatBottomSheet> createState() => _StartSecureChatBottomSheetState();
}

class _StartSecureChatBottomSheetState extends ConsumerState<StartSecureChatBottomSheet> {
  final _logger = Logger('StartSecureChatBottomSheet');
  bool _isCreatingGroup = false;

  Future<void> _createOrOpenDirectMessageGroup() async {
    setState(() {
      _isCreatingGroup = true;
    });

    try {
      final groupData = await ref
          .read(groupsProvider.notifier)
          .createNewGroup(
            groupName: 'DM',
            groupDescription: 'Direct message',
            memberPublicKeyHexs: [widget.pubkey],
            adminPublicKeyHexs: [widget.pubkey],
          );

      if (groupData != null) {
        _logger.info('Direct message group created successfully: ${groupData.mlsGroupId}');

        if (mounted) {
          Navigator.pop(context);

          // Call the appropriate callback
          if (widget.onChatCreated != null) {
            widget.onChatCreated?.call(groupData);
          } else if (widget.onStartChat != null) {
            widget.onStartChat!();
          }

          ref.showSuccessToast('Chat with ${widget.name} started successfully');
        }
      } else {
        // Group creation failed - check the provider state for the error message
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Gap(12.h),
              ContactAvatar(
                imageUrl: widget.imagePath ?? '',
                displayName: widget.name,
                size: 96.r,
              ),
              Gap(8.h),
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
              if (widget.nip05.isNotEmpty) ...[
                Gap(2.h),

                Text(
                  widget.nip05,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.colors.mutedForeground,
                  ),
                ),
              ],
              Gap(16.h),

              Text(
                widget.pubkey.formatPublicKey(),
                textAlign: TextAlign.center,
              ),
              Gap(48.h),
            ],
          ),
        ),
        AppFilledButton(
          onPressed: _isCreatingGroup ? null : _createOrOpenDirectMessageGroup,
          loading: _isCreatingGroup,
          title: _isCreatingGroup ? 'Creating Chat...' : 'Start Chat',
        ),
      ],
    );
  }
}
