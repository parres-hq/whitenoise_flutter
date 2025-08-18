import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/domain/services/key_package_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/contact_list/widgets/share_invite_button.dart';
import 'package:whitenoise/ui/contact_list/widgets/share_invite_callout.dart';
import 'package:whitenoise/ui/contact_list/widgets/user_profile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';

class StartChatBottomSheet extends ConsumerStatefulWidget {
  final ContactModel contact;
  final ValueChanged<GroupData?>? onChatCreated;
  final KeyPackageService? keyPackageService;

  const StartChatBottomSheet({
    super.key,
    required this.contact,
    this.onChatCreated,
    this.keyPackageService,
  });

  static Future<void> show({
    required BuildContext context,
    required ContactModel contact,
    ValueChanged<GroupData?>? onChatCreated,
    KeyPackageService? keyPackageService,
  }) {
    return WnBottomSheet.show(
      context: context,
      title: 'User Profile',
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder:
          (context) => StartChatBottomSheet(
            contact: contact,
            onChatCreated: onChatCreated,
            keyPackageService: keyPackageService,
          ),
    );
  }

  @override
  ConsumerState<StartChatBottomSheet> createState() => _StartChatBottomSheetState();
}

class _StartChatBottomSheetState extends ConsumerState<StartChatBottomSheet> {
  final _logger = Logger('StartChatBottomSheet');
  bool _isCreatingGroup = false;
  bool _isAddingContact = false;
  bool _isLoadingKeyPackage = true;
  bool _isLoadingKeyPackageError = false;
  bool _needsInvite = false;

  @override
  void initState() {
    super.initState();
    _loadKeyPackage();
  }

  Future<void> _loadKeyPackage() async {
    final activeAccountData = await ref.read(activeAccountProvider.notifier).getActiveAccountData();
    if (activeAccountData == null) {
      ref.showErrorToast('No active account found');
      return;
    }
    try {
      final keyPackageService =
          widget.keyPackageService ??
          KeyPackageService(
            publicKeyString: widget.contact.publicKey,
            nip65Relays: activeAccountData.nip65Relays,
          );
      final keyPackage = await keyPackageService.fetchWithRetry();

      if (mounted) {
        setState(() {
          _isLoadingKeyPackage = false;
          _needsInvite = keyPackage == null;
        });
      }
    } catch (e) {
      _logger.warning('Failed to fetch key package: $e');
      if (mounted) {
        setState(() {
          _isLoadingKeyPackage = false;
          _isLoadingKeyPackageError = true;
          ref.showErrorToast('Error loading contact: $e');
        });
      }
    }
  }

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
            memberPublicKeyHexs: [widget.contact.publicKey],
            adminPublicKeyHexs: [widget.contact.publicKey],
          );

      if (groupData != null) {
        _logger.info('Direct message group created successfully: ${groupData.mlsGroupId}');

        if (mounted) {
          Navigator.pop(context);

          if (widget.onChatCreated != null) {
            widget.onChatCreated?.call(groupData);
          }

          ref.showSuccessToast(
            'Chat with ${widget.contact.displayName} started successfully',
          );
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
      (contact) => contact.publicKey.toLowerCase() == widget.contact.publicKey.toLowerCase(),
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
        await contactsNotifier.removeContactByHex(widget.contact.publicKey);
        if (mounted) {
          ref.showSuccessToast('${widget.contact.displayName} removed from contacts');
        }
      } else {
        // Add contact
        await contactsNotifier.addContactByHex(widget.contact.publicKey);
        if (mounted) {
          ref.showSuccessToast('${widget.contact.displayName} added to contacts');
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

  void _openAddToGroup() {
    if (widget.contact.publicKey.isEmpty) {
      ref.showErrorToast('No user to add to group');
      return;
    }
    context.push('/add_to_group/${widget.contact.publicKey}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              Gap(12.h),
              UserProfile(
                imageUrl: widget.contact.imagePath ?? '',
                name: widget.contact.displayName,
                nip05: widget.contact.nip05 ?? '',
                pubkey: widget.contact.publicKey,
                ref: ref,
              ),
              Gap(36.h),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child:
                _isLoadingKeyPackageError
                    ? const SizedBox.shrink(key: ValueKey('error'))
                    : _isLoadingKeyPackage
                    ? Center(
                      key: const ValueKey('loading'),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.h),
                        child: SizedBox(
                          width: 32.w,
                          height: 32.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.0,
                            valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                          ),
                        ),
                      ),
                    )
                    : _needsInvite
                    ? Column(
                      key: const ValueKey('invite'),
                      children: [
                        ShareInviteCallout(contact: widget.contact),
                        Gap(10.h),
                        const ShareInviteButton(),
                      ],
                    )
                    : Column(
                      key: const ValueKey('buttons'),
                      children: [
                        WnFilledButton(
                          size: WnButtonSize.small,
                          visualState: WnButtonVisualState.secondary,
                          onPressed: _isAddingContact ? null : _toggleContact,
                          label: _isContact() ? 'Remove Contact' : 'Add Contact',
                          suffixIcon: SvgPicture.asset(
                            _isContact() ? AssetsPaths.icRemoveUser : AssetsPaths.icAddUser,
                            width: 18.w,
                            height: 18.w,
                            colorFilter: ColorFilter.mode(
                              context.colors.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        Gap(8.h),
                        WnFilledButton(
                          size: WnButtonSize.small,
                          visualState: WnButtonVisualState.secondary,
                          onPressed: _openAddToGroup,
                          label: 'Add to Group',
                          suffixIcon: SvgPicture.asset(
                            AssetsPaths.icChatInvite,
                            width: 18.w,
                            height: 18.w,
                            colorFilter: ColorFilter.mode(
                              context.colors.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        Gap(8.h),
                        WnFilledButton(
                          onPressed: _isCreatingGroup ? null : _createOrOpenDirectMessageGroup,
                          loading: _isCreatingGroup,
                          label: _isCreatingGroup ? 'Creating Chat...' : 'Start Chat',
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }
}
