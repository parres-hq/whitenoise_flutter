import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
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
      heightFactor: 0.65,
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

  Future<void> _createDirectMessageGroup() async {
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
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Gap(48.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(40.r),
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: context.colors.warning,
                    borderRadius: BorderRadius.circular(40.r),
                  ),
                  child:
                      widget.imagePath != null && widget.imagePath!.isNotEmpty
                          ? Image.network(
                            widget.imagePath!,
                            width: 80.w,
                            height: 80.w,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Center(
                                  child: Text(
                                    widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: context.colors.neutral,
                                      fontSize: 32.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                          )
                          : Center(
                            child: Text(
                              widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: context.colors.neutral,
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                ),
              ),
              Gap(12.h),
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w500,
                  color: context.colors.primary,
                ),
              ),
              Gap(12.h),

              Text(
                widget.nip05,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                ),
              ),
              Gap(12.h),
              Text(
                widget.pubkey.formatPublicKey(),
                textAlign: TextAlign.center,
              ),
              Gap(12.h),

              if (widget.bio != null && widget.bio!.isNotEmpty) ...[
                Gap(8.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    widget.bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.colors.mutedForeground,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              Gap(48.h),
            ],
          ),
        ),
        AppFilledButton(
          onPressed: _isCreatingGroup ? null : _createDirectMessageGroup,
          title: _isCreatingGroup ? 'Creating Chat...' : 'Start Chat',
        ),
      ],
    );
  }
}
