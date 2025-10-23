import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/users.dart' as rust_users;
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/ui/user_profile_list/safe_toast_mixin.dart';
import 'package:whitenoise/ui/user_profile_list/widgets/user_profile_tile.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';

class AddGroupMembersScreen extends ConsumerStatefulWidget {
  final String groupId;
  final List<String> existingMemberPubkeys;

  const AddGroupMembersScreen({
    super.key,
    required this.groupId,
    required this.existingMemberPubkeys,
  });

  @override
  ConsumerState<AddGroupMembersScreen> createState() => _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends ConsumerState<AddGroupMembersScreen> with SafeToastMixin {
  final _logger = Logger('AddGroupMembersScreen');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<rust_users.User> _selectedFollows = {};
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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

    // Only remove whitespace if it looks like a public key (starts with npub)
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

  void _toggleUserSelection(rust_users.User user, bool isExistingMember) {
    if (isExistingMember) return;

    setState(() {
      if (_selectedFollows.contains(user)) {
        _selectedFollows.remove(user);
      } else {
        _selectedFollows.add(user);
      }
    });
  }

  Future<void> _addMembersToGroup() async {
    if (_selectedFollows.isEmpty) return;

    setState(() {
      _isAdding = true;
    });

    try {
      final activePubkey = ref.read(activePubkeyProvider);
      if (activePubkey == null) {
        safeShowErrorToast('settings.noActiveAccountFound'.tr());
        return;
      }

      final memberPubkeysToAdd = _selectedFollows.map((user) => user.pubkey).toList();

      await addMembersToGroup(
        pubkey: activePubkey,
        groupId: widget.groupId,
        memberPubkeys: memberPubkeysToAdd,
      );

      await ref.read(groupsProvider.notifier).loadGroups();

      if (mounted) {
        safeShowSuccessToast('ui.membersAddedSuccess'.tr());
        context.pop();
      }
    } catch (e, st) {
      _logger.severe('Error adding members to group', e, st);
      safeShowErrorToast('ui.failedToAddMembers'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  List<rust_users.User> _getFilteredFollows(
    List<rust_users.User>? follows,
    String? currentUserPubkey,
  ) {
    if (follows == null) return [];

    final availableFollows =
        follows.where((user) {
          final userPubkey = user.pubkey.trim().toLowerCase();

          if (currentUserPubkey != null && userPubkey == currentUserPubkey.trim().toLowerCase()) {
            return false;
          }

          return true;
        }).toList();

    if (_searchQuery.isEmpty) return availableFollows;

    return availableFollows.where(
      (user) {
        final displayName = user.metadata.displayName ?? user.metadata.name ?? '';
        final nip05 = user.metadata.nip05 ?? '';
        return displayName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            nip05.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            user.pubkey.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      },
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final followsState = ref.watch(followsProvider);
    final activeAccount = ref.watch(activePubkeyProvider);
    final filteredFollows = _getFilteredFollows(followsState.follows, activeAccount);

    return Scaffold(
      backgroundColor: context.colors.neutral,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 16.h),
            height: MediaQuery.of(context).padding.top,
            color: context.colors.appBarBackground,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ui.addMembers'.tr(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.mutedForeground,
                    fontSize: 18.sp,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: context.colors.primary,
                    size: 24.sp,
                  ),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
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
          Gap(16.h),
          _SelectedChips(
            selectedFollows: _selectedFollows,
            onRemove: (user) => _toggleUserSelection(user, false),
          ),
          Expanded(
            child: Stack(
              children: [
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
                        ],
                      ),
                    )
                    : _FollowsList(
                      follows: filteredFollows,
                      selectedFollows: _selectedFollows,
                      existingMemberPubkeys: widget.existingMemberPubkeys,
                      onToggleSelection: _toggleUserSelection,
                      searchQuery: _searchQuery,
                    ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 20.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.colors.neutral.withValues(alpha: 0.0),
                            context.colors.neutral.withValues(alpha: 0.5),
                            context.colors.neutral,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: context.colors.neutral,
            child: Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.viewInsetsOf(context).bottom > 0
                        ? 16.h
                        : MediaQuery.viewPaddingOf(context).bottom + 16.h,
                left: 16.w,
                right: 16.w,
              ),
              child: WnFilledButton(
                onPressed: _selectedFollows.isNotEmpty && !_isAdding ? _addMembersToGroup : null,
                loading: _isAdding,
                label: _isAdding ? 'ui.addingMembers'.tr() : 'ui.addMembers'.tr(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedChips extends StatelessWidget {
  final Set<rust_users.User> selectedFollows;
  final ValueChanged<rust_users.User> onRemove;

  const _SelectedChips({
    required this.selectedFollows,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedFollows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children:
            selectedFollows.map((follow) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WnAvatar(
                      imageUrl: follow.metadata.picture ?? '',
                      displayName: follow.metadata.displayName ?? follow.metadata.name ?? '',
                      size: 18.w,
                      showBorder: true,
                    ),
                    Gap(8.w),
                    Text(
                      (follow.metadata.displayName ?? follow.metadata.name ?? '').split(' ').first,
                      style: TextStyle(
                        color: context.colors.primaryForeground,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Gap(8.w),
                    GestureDetector(
                      onTap: () => onRemove(follow),
                      child: Padding(
                        padding: EdgeInsets.only(right: 4.w),
                        child: Icon(
                          Icons.close,
                          size: 16.sp,
                          color: context.colors.primaryForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _FollowsList extends StatelessWidget {
  final List<rust_users.User> follows;
  final Set<rust_users.User> selectedFollows;
  final List<String> existingMemberPubkeys;
  final Function(rust_users.User, bool) onToggleSelection;
  final String searchQuery;

  const _FollowsList({
    required this.follows,
    required this.selectedFollows,
    required this.existingMemberPubkeys,
    required this.onToggleSelection,
    required this.searchQuery,
  });

  bool _isExistingMember(rust_users.User user) {
    try {
      // Normalize both pubkeys to hex format for comparison
      final userHexPubkey = PubkeyFormatter(pubkey: user.pubkey).toHex()?.toLowerCase();
      if (userHexPubkey == null) return false;

      return existingMemberPubkeys.any((memberPubkey) {
        try {
          final memberHexPubkey = PubkeyFormatter(pubkey: memberPubkey).toHex()?.toLowerCase();
          return memberHexPubkey == userHexPubkey;
        } catch (e) {
          return false;
        }
      });
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (follows.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(
            searchQuery.isEmpty ? 'chats.noFollowsFound'.tr() : 'chats.noFollowsMatchSearch'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              color: context.colors.mutedForeground,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: follows.length,
            itemBuilder: (context, index) {
              final follow = follows[index];
              final isExistingMember = _isExistingMember(follow);
              final isSelected = selectedFollows.contains(follow) || isExistingMember;

              return Opacity(
                opacity: isExistingMember ? 0.4 : 1.0,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: UserProfileTile(
                    userProfile: UserProfile.fromMetadata(
                      pubkey: follow.pubkey,
                      metadata: follow.metadata,
                    ),
                    isSelected: isSelected,
                    onTap: () => onToggleSelection(follow, isExistingMember),
                    showCheck: true,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
