part of 'chat_info_screen.dart';

class GroupChatInfo extends ConsumerStatefulWidget {
  const GroupChatInfo({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<GroupChatInfo> createState() => _GroupChatInfoState();
}

class _GroupChatInfoState extends ConsumerState<GroupChatInfo> {
  final _logger = Logger('GroupChatInfo');
  String? groupNpub;
  List<User> groupMembers = [];
  List<User> groupAdmins = [];
  bool isLoadingMembers = false;
  String? currentUserNpub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroup();
      _loadMembers();
      _loadCurrentUserNpub();
    });
  }

  Future<void> _loadGroup() async {
    final groupDetails = ref.read(groupsProvider).groupsMap?[widget.groupId];
    if (groupDetails?.nostrGroupId != null) {
      try {
        final npub = await npubFromHexPubkey(
          hexPubkey: groupDetails!.nostrGroupId,
        );
        if (mounted) {
          setState(() {
            groupNpub = npub;
          });
        }
      } catch (e) {
        _logger.warning('Error converting nostrGroupId to npub: $e');
      }
    }
  }

  Future<void> _loadMembers() async {
    setState(() {
      isLoadingMembers = true;
    });

    try {
      final members = ref.read(groupsProvider).groupMembers?[widget.groupId] ?? [];
      final admins = ref.read(groupsProvider).groupAdmins?[widget.groupId] ?? [];

      final allMembers = <User>[];

      allMembers.addAll(members);

      for (final admin in admins) {
        if (!members.any((member) => member.publicKey == admin.publicKey)) {
          allMembers.add(admin);
        }
      }

      // Sort members: admins first (A-Z), then regular members (A-Z), current user last
      allMembers.sort((a, b) {
        final aIsAdmin = admins.any((admin) => admin.publicKey == a.publicKey);
        final bIsAdmin = admins.any((admin) => admin.publicKey == b.publicKey);
        final aIsCurrentUser = currentUserNpub != null && currentUserNpub == a.publicKey;
        final bIsCurrentUser = currentUserNpub != null && currentUserNpub == b.publicKey;

        // Current user always goes last
        if (aIsCurrentUser) return 1;
        if (bIsCurrentUser) return -1;

        // Admins come before regular members
        if (aIsAdmin && !bIsAdmin) return -1;
        if (!aIsAdmin && bIsAdmin) return 1;

        // Within same category (both admins or both regular), sort alphabetically
        final aName = a.displayName.isNotEmpty ? a.displayName : 'Unknown User';
        final bName = b.displayName.isNotEmpty ? b.displayName : 'Unknown User';
        return aName.toLowerCase().compareTo(bName.toLowerCase());
      });

      if (mounted) {
        setState(() {
          groupMembers = allMembers;
          groupAdmins = admins;
        });
      }
    } catch (e) {
      _logger.warning('Error loading members: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingMembers = false;
        });
      }
    }
  }

  Future<void> _loadCurrentUserNpub() async {
    final activeAccount = ref.read(activePubkeyProvider);
    if (activeAccount != null) {
      final currentUserNpub = await npubFromHexPubkey(hexPubkey: activeAccount);
      if (mounted) {
        setState(() {
          this.currentUserNpub = currentUserNpub;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupDetails = ref.watch(groupsProvider).groupsMap?[widget.groupId];
    ref.listen(groupsProvider, (previous, next) {
      _loadMembers();
    });
    final isAdmin = groupAdmins.any((admin) {
      final hexAdminKey = PubkeyFormatter(pubkey: admin.publicKey).toHex();
      final hexCurrentUserKey = PubkeyFormatter(pubkey: currentUserNpub).toHex();
      return hexAdminKey == hexCurrentUserKey;
    });

    final groupDescription = groupDetails?.description ?? '';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Gap(64.h),
          WnAvatar(
            imageUrl: '',
            displayName: groupDetails?.name ?? 'Unknown Group',
            size: 96.w,
          ),
          SizedBox(height: 8.h),
          Text(
            groupDetails?.name ?? 'Unknown Group',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.primary,
              fontSize: 18.sp,
            ),
          ),
          Gap(16.h),
          if (groupDescription.isNotEmpty) ...[
            Text(
              'Group Description:',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.mutedForeground,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              groupDetails?.description ?? '',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.primary,
                fontSize: 14.sp,
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: () {},
              child: Text(
                isAdmin ? 'Add Group Description...' : 'No Description',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.mutedForeground,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          Gap(36.h),
          // TODO: Reenable when we have a search and mute features
          if (isAdmin) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  Row(
                    spacing: 8.w,
                    children: [
                      Expanded(
                        child: WnIconButton(
                          iconPath: AssetsPaths.icSearch,
                          onTap: () {},
                        ),
                      ),
                      Expanded(
                        child: WnIconButton(
                          iconPath: AssetsPaths.icMutedNotification,
                          onTap: () {},
                        ),
                      ),
                      Expanded(
                        child: WnIconButton(
                          iconPath: AssetsPaths.icGroupSettings,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  Gap(8.h),
                  WnFilledButton(
                    size: WnButtonSize.small,
                    prefixIcon: WnImage(
                      AssetsPaths.icAddUser,
                      width: 14.w,
                      color: context.colors.primaryForeground,
                    ),
                    label: 'Add Member',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              spacing: 12.w,
              children: [
                Expanded(
                  child: WnFilledButton(
                    visualState: WnButtonVisualState.secondary,
                    suffixIcon: WnImage(
                      AssetsPaths.icSearch,
                      width: 14.w,
                      color: context.colors.primary,
                    ),
                    label: 'Search Chat',
                    onPressed: () {},
                  ),
                ),
                Expanded(
                  child: WnFilledButton(
                    visualState: WnButtonVisualState.secondary,
                    suffixIcon: WnImage(
                      AssetsPaths.icMutedNotification,
                      width: 14.w,
                      color: context.colors.primary,
                    ),
                    label: 'Mute Chat',
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
          Gap(32.h),
          if (isLoadingMembers)
            const CircularProgressIndicator()
          else if (groupMembers.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'Members:',
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.mutedForeground,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Gap(16.h),
                ...groupMembers.map(
                  (member) => _buildMemberListTile(
                    member,
                    currentUserNpub: currentUserNpub,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberListTile(User member, {String? currentUserNpub}) {
    final isAdmin = groupAdmins.any((admin) => admin.publicKey == member.publicKey);
    final isCurrentUser = currentUserNpub != null && currentUserNpub == member.publicKey;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),

      onTap:
          isCurrentUser
              ? null
              : () => GroupMemberBottomSheet.show(
                context,
                groupId: widget.groupId,
                member: member,
              ),
      leading: WnAvatar(
        imageUrl: member.imagePath ?? '',
        displayName: member.displayName,
        size: 40.w,
        showBorder: true,
      ),
      title: Text(
        isCurrentUser
            ? 'You'
            : member.displayName.isNotEmpty
            ? member.displayName
            : 'Unknown User',
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 16.sp,
        ),
      ),
      subtitle:
          isAdmin
              ? Text(
                '(Admin)',
                style: TextStyle(
                  color: context.colors.mutedForeground,
                  fontSize: 12.sp,
                ),
              )
              : null,
    );
  }
}
