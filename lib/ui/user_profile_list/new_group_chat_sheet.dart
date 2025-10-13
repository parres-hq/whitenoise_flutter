import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_icon_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/ui/user_profile_list/group_chat_details_sheet.dart';
import 'package:whitenoise/ui/user_profile_list/widgets/user_profile_tile.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class NewGroupChatSheet extends ConsumerStatefulWidget {
  final ValueChanged<Group?>? onGroupCreated;
  final List<UserProfile>? preSelectedUserProfiles;

  const NewGroupChatSheet({super.key, this.onGroupCreated, this.preSelectedUserProfiles});

  @override
  ConsumerState<NewGroupChatSheet> createState() => _NewGroupChatSheetState();

  static Future<void> show(
    BuildContext context, {
    ValueChanged<Group?>? onGroupCreated,
    List<UserProfile>? preSelectedUserProfiles,
  }) {
    return WnBottomSheet.show(
      context: context,
      title: 'ui.newGroupChat'.tr(),
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder:
          (context) => NewGroupChatSheet(
            onGroupCreated: onGroupCreated,
            preSelectedUserProfiles: preSelectedUserProfiles,
          ),
    );
  }
}

class _NewGroupChatSheetState extends ConsumerState<NewGroupChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<UserProfile> _selectedUserProfiles = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Add pre-selected user profiles to the selection
    if (widget.preSelectedUserProfiles != null) {
      _selectedUserProfiles.addAll(widget.preSelectedUserProfiles!);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final originalText = _searchController.text;
    String processedText = originalText;

    // Only remove whitespace if it looks like a public key (starts with npub or is hex-like)
    if (originalText.startsWith('npub')) {
      processedText = originalText.replaceAll(RegExp(r'\s+'), '');

      // Update the controller if we removed whitespace
      if (originalText != processedText) {
        _searchController.value = _searchController.value.copyWith(
          text: processedText,
          selection: TextSelection.collapsed(offset: processedText.length),
        );
      }
    }

    setState(() {
      _searchQuery = processedText;
    });
  }

  void _toggleUserProfileSelection(UserProfile userProfile) {
    setState(() {
      if (_selectedUserProfiles.contains(userProfile)) {
        _selectedUserProfiles.remove(userProfile);
      } else {
        _selectedUserProfiles.add(userProfile);
      }
    });
  }

  Widget _buildUserProfilesList(List<UserProfile> filteredUserProfiles) {
    if (filteredUserProfiles.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'chats.noUsersFound'.tr() : 'chats.noUsersMatchSearch'.tr(),
          style: TextStyle(fontSize: 16.sp),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: filteredUserProfiles.length,
      itemBuilder: (context, index) {
        final userProfile = filteredUserProfiles[index];
        final isSelected = _selectedUserProfiles.contains(userProfile);

        return UserProfileTile(
          userProfile: userProfile,
          isSelected: isSelected,
          onTap: () => _toggleUserProfileSelection(userProfile),
          showCheck: true,
        );
      },
    );
  }

  List<UserProfile> _getFilteredUserProfiles(
    List<UserProfile>? userProfiles,
    String? currentUserPubkey,
  ) {
    if (userProfiles == null) return [];

    // First filter out the creator (current user) from the userProfiles
    final userProfilesWithoutCreator =
        userProfiles.where((userProfile) {
          // Compare public keys, ensuring both are trimmed and lowercased for comparison
          return currentUserPubkey == null ||
              userProfile.publicKey.trim().toLowerCase() != currentUserPubkey.trim().toLowerCase();
        }).toList();

    // Then apply search filter if there's a search query
    if (_searchQuery.isEmpty) return userProfilesWithoutCreator;

    return userProfilesWithoutCreator
        .where(
          (userProfile) =>
              userProfile.displayName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (userProfile.nip05?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              userProfile.publicKey.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final followsState = ref.watch(followsProvider);
    final activeAccount = ref.watch(activePubkeyProvider);
    final follows = followsState.follows;
    final userProfiles = follows.map(
      (follow) => UserProfile.fromMetadata(pubkey: follow.pubkey, metadata: follow.metadata),
    );
    final filteredUserProfiles = _getFilteredUserProfiles(userProfiles.toList(), activeAccount);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: WnTextFormField(
                controller: _searchController,
                hintText: 'chats.searchUserPlaceholder'.tr(),
                size: FieldSize.small,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: WnImage(
                      AssetsPaths.icSearch,
                      color: context.colors.primary,
                      size: 16.w,
                    ),
                  ),
                ),
              ),
            ),
            Gap(4.w),
            WnIconButton(
              iconPath: AssetsPaths.icPaste,
              onTap:
                  () async => await ClipboardUtils.pasteWithToast(
                    ref: ref,
                    onPaste: (text) {
                      _searchController.text = text;
                    },
                  ),
              padding: 14.w,
              size: 44.h,
            ),
          ],
        ),
        Expanded(
          child:
              followsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : followsState.error != null
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'chats.followsLoadingError'.tr(),
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        Gap(8.h),
                        Text(
                          followsState.error!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: context.colors.baseMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Gap(16.h),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate back - contacts should be loaded by new_chat_bottom_sheet
                            Navigator.of(context).pop();
                          },
                          child: Text('shared.goBack'.tr()),
                        ),
                      ],
                    ),
                  )
                  : _buildUserProfilesList(filteredUserProfiles),
        ),
        WnFilledButton(
          onPressed:
              _selectedUserProfiles.isNotEmpty
                  ? () {
                    Navigator.pop(context);
                    GroupChatDetailsSheet.show(
                      context: context,
                      selectedUserProfiles: _selectedUserProfiles.toList(),
                      onGroupCreated: widget.onGroupCreated,
                    );
                  }
                  : null,
          label: 'shared.continue'.tr(),
        ),
      ],
    );
  }
}
