import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/relays.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/contact_list/share_invite_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class GroupChatDetailsSheet extends ConsumerStatefulWidget {
  const GroupChatDetailsSheet({
    super.key,
    required this.selectedContacts,
    this.onGroupCreated,
  });

  final List<ContactModel> selectedContacts;
  final ValueChanged<GroupData?>? onGroupCreated;

  static Future<void> show({
    required BuildContext context,
    required List<ContactModel> selectedContacts,
    ValueChanged<GroupData?>? onGroupCreated,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Group chat details',
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder:
          (context) => GroupChatDetailsSheet(
            selectedContacts: selectedContacts,
            onGroupCreated: onGroupCreated,
          ),
    );
  }

  @override
  ConsumerState<GroupChatDetailsSheet> createState() => _GroupChatDetailsSheetState();
}

class _GroupChatDetailsSheetState extends ConsumerState<GroupChatDetailsSheet> {
  final TextEditingController _groupNameController = TextEditingController();
  bool _hasGroupImage = false;
  bool _isGroupNameValid = false;
  bool _isCreatingGroup = false;
  bool _hasContactsWithKeyPackage = true;

  @override
  void initState() {
    super.initState();
    _groupNameController.addListener(_onGroupNameChanged);
    _checkContactsKeyPackages();
  }

  void _onGroupNameChanged() {
    final isValid = _groupNameController.text.trim().isNotEmpty;
    if (isValid != _isGroupNameValid) {
      setState(() {
        _isGroupNameValid = isValid;
      });
    }
  }

  Future<void> _checkContactsKeyPackages() async {
    try {
      final filteredContacts = await _filterContactsByKeyPackage(widget.selectedContacts);
      final contactsWithKeyPackage = filteredContacts['withKeyPackage']!;

      setState(() {
        _hasContactsWithKeyPackage = contactsWithKeyPackage.isNotEmpty;
      });
    } catch (e) {
      // If there's an error checking keypackages, assume no contacts have keypackages
      setState(() {
        _hasContactsWithKeyPackage = false;
      });
    }
  }

  void _createGroupChat() async {
    if (!_isGroupNameValid) return;
    final groupName = _groupNameController.text.trim();

    setState(() {
      _isCreatingGroup = true;
    });

    try {
      // Filter contacts based on keypackage availability
      final filteredContacts = await _filterContactsByKeyPackage(widget.selectedContacts);
      final contactsWithKeyPackage = filteredContacts['withKeyPackage']!;
      final contactsWithoutKeyPackage = filteredContacts['withoutKeyPackage']!;

      if (contactsWithKeyPackage.isEmpty) {
        if (mounted) {
          ref.showErrorToast('No contacts have keypackages available for group creation');
        }
        return;
      }

      // Create group with contacts that have keypackages
      final groupData = await ref
          .read(groupsProvider.notifier)
          .createNewGroup(
            groupName: groupName,
            groupDescription: '',
            memberPublicKeyHexs: contactsWithKeyPackage.map((c) => c.publicKey).toList(),
            adminPublicKeyHexs: [],
          );

      if (mounted) {
        if (groupData != null) {
          // Show share invite bottom sheet for members without keypackages
          if (contactsWithoutKeyPackage.isNotEmpty) {
            await ShareInviteBottomSheet.show(
              context: context,
              contacts: contactsWithoutKeyPackage,
            );
          }
          widget.onGroupCreated?.call(groupData);
        } else {
          if (mounted) {
            ref.showErrorToast('Failed to create group chat. Please try again.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Error creating group: ${e.toString()}');
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
  void dispose() {
    _groupNameController.removeListener(_onGroupNameChanged);
    _groupNameController.dispose();
    super.dispose();
  }

  /// Filters contacts by keypackage availability
  Future<Map<String, List<ContactModel>>> _filterContactsByKeyPackage(
    List<ContactModel> contacts,
  ) async {
    final contactsWithKeyPackage = <ContactModel>[];
    final contactsWithoutKeyPackage = <ContactModel>[];

    for (final contact in contacts) {
      try {
        final pubkey = await publicKeyFromString(publicKeyString: contact.publicKey);
        final keyPackage = await fetchKeyPackage(pubkey: pubkey);

        if (keyPackage != null) {
          contactsWithKeyPackage.add(contact);
        } else {
          contactsWithoutKeyPackage.add(contact);
        }
      } catch (e) {
        // If there's an error checking keypackage, assume contact doesn't have one
        contactsWithoutKeyPackage.add(contact);
      }
    }

    return {
      'withKeyPackage': contactsWithKeyPackage,
      'withoutKeyPackage': contactsWithoutKeyPackage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _hasGroupImage = !_hasGroupImage;
              });
            },
            child: Container(
              width: 80.w,
              height: 80.w,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.colors.baseMuted,
                shape: BoxShape.circle,
              ),
              child:
                  _hasGroupImage
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(40.r),
                        child: Image.asset(
                          AssetsPaths.icWhiteNoise,
                          fit: BoxFit.cover,
                        ),
                      )
                      : SvgPicture.asset(
                        AssetsPaths.icCamera,
                        width: 42.w,
                        height: 42.w,
                        colorFilter: ColorFilter.mode(
                          context.colors.mutedForeground,
                          BlendMode.srcIn,
                        ),
                      ),
            ),
          ),
        ),
        Gap(24.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Group chat name',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: context.colors.primary,
                ),
              ),
              Gap(8.h),
              CustomTextField(
                textController: _groupNameController,
                hintText: 'Enter group name',
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        Gap(24.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Members',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: context.colors.primary,
            ),
          ),
        ),
        Gap(8.h),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: widget.selectedContacts.length,
            itemBuilder: (context, index) {
              final contact = widget.selectedContacts[index];
              return ContactListTile(contact: contact);
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(bottom: 16.h),
            child: AppFilledButton(
              onPressed:
                  _isCreatingGroup || !_isGroupNameValid || !_hasContactsWithKeyPackage
                      ? null
                      : () => _createGroupChat(),
              loading: _isCreatingGroup,
              title: _isCreatingGroup ? 'Creating Group...' : 'Create Group',
            ),
          ),
        ),
      ],
    );
  }
}
