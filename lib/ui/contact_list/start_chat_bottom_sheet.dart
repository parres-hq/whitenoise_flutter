import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
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
      title: 'User Profile',
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
  bool _isAddingContact = false;

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

  bool _isContact() {
    final contactsState = ref.watch(contactsProvider);
    final contacts = contactsState.contactModels ?? [];

    // Check if the current user's pubkey exists in contacts
    return contacts.any(
      (contact) => contact.publicKey.toLowerCase() == widget.pubkey.toLowerCase(),
    );
  }

  Future<void> _toggleContact() async {
    setState(() {
      _isAddingContact = true;
    });

    try {
      final contactsNotifier = ref.read(contactsProvider.notifier);
      final isCurrentlyContact = _isContact();

      if (isCurrentlyContact) {
        // Remove contact
        await contactsNotifier.removeContactByHex(widget.pubkey);
        if (mounted) {
          ref.showSuccessToast('${widget.name} removed from contacts');
        }
      } else {
        // Add contact
        await contactsNotifier.addContactByHex(widget.pubkey);
        if (mounted) {
          ref.showSuccessToast('${widget.name} added to contacts');
        }
      }
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to update contact: $e');
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
        AppFilledButton.child(
          size: AppButtonSize.small,
          visualState: AppButtonVisualState.secondary,
          onPressed: _isAddingContact ? null : _toggleContact,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isAddingContact)
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    color: context.colors.primary,
                  ),
                )
              else ...[
                Text(
                  _isContact() ? 'Remove Contact' : 'Add Contact',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
                Gap(9.w),
                SvgPicture.asset(
                  _isContact() ? 'assets/svgs/ic_remove_user.svg' : 'assets/svgs/ic_add_user.svg',
                  width: 16.w,
                  height: 16.w,
                  colorFilter: ColorFilter.mode(
                    context.colors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ],
          ),
        ),
        Gap(8.h),
        AppFilledButton(
          onPressed: _isCreatingGroup ? null : _createOrOpenDirectMessageGroup,
          loading: _isCreatingGroup,
          title: _isCreatingGroup ? 'Creating Chat...' : 'Start Chat',
        ),
      ],
    );
  }
}
