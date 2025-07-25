import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/routing/chat_navigation_extension.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';

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
      final groupData = await ref
          .read(groupsProvider.notifier)
          .createNewGroup(
            groupName: 'DM',
            groupDescription: 'Direct message',
            memberPublicKeyHexs: [widget.user.publicKey],
            adminPublicKeyHexs: [widget.user.publicKey],
          );

      if (groupData != null) {
        _logger.info('Direct message group created successfully: ${groupData.mlsGroupId}');

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context);
              context.navigateToGroupChatAndPopToHome(groupData);
            }
          });

          ref.showSuccessToast(
            'Chat with ${widget.user.username ?? widget.user.displayName} started successfully',
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
    return WnFilledButton.child(
      onPressed: _createOrOpenDirectMessageGroup,
      loading: _isLoading,
      size: WnButtonSize.small,
      visualState: WnButtonVisualState.secondary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Send Message',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          Gap(8.w),
          SvgPicture.asset(
            AssetsPaths.icMessage,
            width: 14.w,
            height: 13.h,
            colorFilter: ColorFilter.mode(
              context.colors.primary,
              BlendMode.srcIn,
            ),
          ),
        ],
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
    final contactsState = ref.watch(contactsProvider);
    final contacts = contactsState.contactModels ?? [];

    return contacts.any(
      (contact) => contact.publicKey.toLowerCase() == widget.user.publicKey.toLowerCase(),
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
        await contactsNotifier.removeContactByHex(widget.user.publicKey);
        if (mounted) {
          ref.showSuccessToast('${widget.user.displayName} removed from contacts');
        }
      } else {
        await contactsNotifier.addContactByHex(widget.user.publicKey);
        if (mounted) {
          ref.showSuccessToast('${widget.user.displayName} added to contacts');
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
    final isContact = _isContact();
    return WnFilledButton.child(
      onPressed: _toggleContact,
      loading: _isLoading,
      size: WnButtonSize.small,
      visualState: WnButtonVisualState.secondary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isContact ? 'Remove Contact' : 'Add Contact',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          Gap(8.w),
          SvgPicture.asset(
            isContact ? AssetsPaths.icRemoveUser : AssetsPaths.icAddUser,
            width: 11.w,
            height: 11.w,
            colorFilter: ColorFilter.mode(
              context.colors.primary,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
