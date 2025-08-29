import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/ui/contact_list/safe_toast_mixin.dart';
import 'package:whitenoise/ui/contact_list/share_invite_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_field.dart';

class GroupChatDetailsSheet extends ConsumerStatefulWidget {
  const GroupChatDetailsSheet({
    super.key,
    required this.selectedContacts,
    this.onGroupCreated,
  });

  final List<ContactModel> selectedContacts;
  final ValueChanged<Group?>? onGroupCreated;

  static Future<void> show({
    required BuildContext context,
    required List<ContactModel> selectedContacts,
    ValueChanged<Group?>? onGroupCreated,
  }) {
    return WnBottomSheet.show(
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

class _GroupChatDetailsSheetState extends ConsumerState<GroupChatDetailsSheet> with SafeToastMixin {
  final TextEditingController _groupNameController = TextEditingController();
  bool _isGroupNameValid = false;
  bool _isCreatingGroup = false;

  @override
  void initState() {
    super.initState();
    _groupNameController.addListener(_onGroupNameChanged);
  }

  void _onGroupNameChanged() {
    final isValid = _groupNameController.text.trim().isNotEmpty;
    if (isValid != _isGroupNameValid) {
      setState(() {
        _isGroupNameValid = isValid;
      });
    }
  }

  void _createGroupChat() async {
    if (!_isGroupNameValid || !mounted) return;

    final groupName = _groupNameController.text.trim();
    final notifier = ref.read(groupsProvider.notifier);

    setState(() {
      _isCreatingGroup = true;
    });

    try {
      // Filter contacts based on keypackage availability
      final filteredContacts = await _filterContactsByKeyPackage(widget.selectedContacts);
      if (!mounted) return;

      final contactsWithKeyPackage = filteredContacts['withKeyPackage']!;
      final contactsWithoutKeyPackage = filteredContacts['withoutKeyPackage']!;

      // If less than 2 contacts have keypackages, only show invite sheet (no group creation)
      if (contactsWithKeyPackage.length < 2) {
        if (contactsWithoutKeyPackage.isNotEmpty && mounted) {
          await ShareInviteBottomSheet.show(
            context: context,
            contacts: contactsWithoutKeyPackage,
          );
        }

        if (mounted) {
          context.pop();
        }
        return;
      }

      // Create group with contacts that have keypackages
      if (!mounted) return;

      final createdGroup = await notifier.createNewGroup(
        groupName: groupName,
        groupDescription: '',
        memberPublicKeyHexs: contactsWithKeyPackage.map((c) => c.publicKey).toList(),
        adminPublicKeyHexs: [],
      );

      if (!mounted) return;

      if (createdGroup != null) {
        // Show share invite bottom sheet for members without keypackages
        if (contactsWithoutKeyPackage.isNotEmpty && mounted) {
          try {
            await ShareInviteBottomSheet.show(
              context: context,
              contacts: contactsWithoutKeyPackage,
            );
          } catch (e) {
            Logger(
              'GroupChatDetailsSheet',
            ).severe('Error showing share invite bottom sheet: $e');
          }
        }

        // Navigate to the created group
        if (mounted) {
          context.pop();

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              context.go(Routes.home);
              // Small delay to ensure navigation completes
              await Future.delayed(const Duration(milliseconds: 150));
              if (mounted) {
                Routes.goToChat(context, createdGroup.mlsGroupId);
              }
            }
          });
        }
      } else {
        safeShowErrorToast('Failed to create group chat. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        safeShowErrorToast('Error creating group: ${e.toString()}');
      }
    } finally {
      // Always reset loading state
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
        final hasKeyPackage = await userHasKeyPackage(pubkey: contact.publicKey);

        if (hasKeyPackage) {
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
              // TODO: implement group image upload.
            },
            child: Container(
              width: 80.w,
              height: 80.w,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.colors.baseMuted,
                shape: BoxShape.circle,
              ),
              child: WnImage(
                AssetsPaths.icCamera,
                size: 42.w,
                color: context.colors.mutedForeground,
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
              WnTextField(
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
        WnFilledButton(
          onPressed: _isCreatingGroup || !_isGroupNameValid ? null : _createGroupChat,
          loading: _isCreatingGroup,
          label: _isCreatingGroup ? 'Creating Group...' : 'Create Group',
        ),
      ],
    );
  }
}
