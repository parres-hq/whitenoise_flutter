import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/relays.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/contact_list/safe_toast_mixin.dart';
import 'package:whitenoise/ui/contact_list/share_invite_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_text_field.dart';

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
      if (!mounted) return;

      final contactsWithKeyPackage = filteredContacts['withKeyPackage']!;

      if (mounted) {
        setState(() {
          _hasContactsWithKeyPackage = contactsWithKeyPackage.isNotEmpty;
        });
      }
    } catch (e) {
      // If there's an error checking keypackages, assume no contacts have keypackages
      if (mounted) {
        setState(() {
          _hasContactsWithKeyPackage = false;
        });
      }
    }
  }

  void _createGroupChat() async {
    if (!_isGroupNameValid) return;
    final groupName = _groupNameController.text.trim();

    // Store the ref early to avoid accessing it after disposal
    final notifier = ref.read(groupsProvider.notifier);

    if (!mounted) return;
    setState(() {
      _isCreatingGroup = true;
    });

    try {
      // Filter contacts based on keypackage availability
      final filteredContacts = await _filterContactsByKeyPackage(widget.selectedContacts);
      if (!mounted) return;

      final contactsWithKeyPackage = filteredContacts['withKeyPackage']!;
      final contactsWithoutKeyPackage = filteredContacts['withoutKeyPackage']!;

      if (contactsWithKeyPackage.isEmpty) {
        safeShowErrorToast('No contacts have keypackages available for group creation');
        return;
      }

      // Create group with contacts that have keypackages - use stored notifier
      final groupData = await notifier.createNewGroup(
        groupName: groupName,
        groupDescription: '',
        memberPublicKeyHexs: contactsWithKeyPackage.map((c) => c.publicKey).toList(),
        adminPublicKeyHexs: [],
      );

      if (!mounted) return;

      GroupData? successGroupData;
      String? errorMessage;

      if (groupData != null) {
        successGroupData = groupData;
        // Show share invite bottom sheet for members without keypackages
        if (contactsWithoutKeyPackage.isNotEmpty && mounted) {
          await ShareInviteBottomSheet.show(
            context: context,
            contacts: contactsWithoutKeyPackage,
          );
        }
      } else {
        errorMessage = 'Failed to create group chat. Please try again.';
      }

      // Complete all local operations first
      if (mounted) {
        setState(() {
          _isCreatingGroup = false;
        });
      }

      // Show error if needed
      if (errorMessage != null) {
        safeShowErrorToast(errorMessage);
      }

      if (successGroupData != null && mounted) {
        // Navigate to home first, then to the group chat
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pop();
            context.go(Routes.home);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Routes.goToChat(context, groupData!.mlsGroupId);
              }
            });
          }
        });
      }

      return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingGroup = false;
        });
      }
      safeShowErrorToast('Error creating group: ${e.toString()}');
      return;
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
    final activeAccountData = await ref.read(activeAccountProvider.notifier).getActiveAccountData();
    if (activeAccountData == null) {
      throw Exception('No active account found');
    }
    final contactsWithKeyPackage = <ContactModel>[];
    final contactsWithoutKeyPackage = <ContactModel>[];

    for (final contact in contacts) {
      try {
        final pubkey = await publicKeyFromString(publicKeyString: contact.publicKey);
        final keyPackage = await fetchKeyPackage(
          pubkey: pubkey,
          nip65Relays: activeAccountData.nip65Relays,
        );

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
          onPressed:
              _isCreatingGroup || !_isGroupNameValid || !_hasContactsWithKeyPackage
                  ? null
                  : () => _createGroupChat(),
          loading: _isCreatingGroup,
          title: _isCreatingGroup ? 'Creating Group...' : 'Create Group',
        ),
      ],
    );
  }
}
