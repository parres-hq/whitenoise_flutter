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
  String? groupImagePath;
  ProviderSubscription<GroupsState>? _groupsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroup();
      _loadMembers();
      _loadCurrentUserNpub();

      setState(() {
        groupImagePath = ref.read(groupsProvider.notifier).getCachedGroupImagePath(widget.groupId);
      });

      _groupsSubscription = ref.listenManual(groupsProvider, (previous, next) {
        if (mounted) {
          _loadMembers();
        }
      });
    });
  }

  @override
  void dispose() {
    _groupsSubscription?.close();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    final groupDetails = ref.read(groupsProvider).groupsMap?[widget.groupId];
    if (groupDetails?.nostrGroupId != null) {
      try {
        final npub = PubkeyFormatter(pubkey: groupDetails?.nostrGroupId).toNpub();
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
        if (!members.any((member) {
          final hexMemberKey = PubkeyFormatter(pubkey: member.publicKey).toHex();
          final hexAdminKey = PubkeyFormatter(pubkey: admin.publicKey).toHex();
          return hexMemberKey == hexAdminKey;
        })) {
          allMembers.add(admin);
        }
      }

      // Sort members: admins first (A-Z), then regular members (A-Z), current user last
      allMembers.sort((a, b) {
        final hexPubkeyA = PubkeyFormatter(pubkey: a.publicKey).toHex();
        final hexPubkeyB = PubkeyFormatter(pubkey: b.publicKey).toHex();
        final hexCurrentUserNpub = PubkeyFormatter(pubkey: currentUserNpub).toHex();
        final aIsAdmin = admins.any((admin) {
          final hexAdminKey = PubkeyFormatter(pubkey: admin.publicKey).toHex();
          return hexAdminKey == hexPubkeyA;
        });
        final bIsAdmin = admins.any((admin) {
          final hexAdminKey = PubkeyFormatter(pubkey: admin.publicKey).toHex();
          return hexAdminKey == hexPubkeyB;
        });
        final aIsCurrentUser = currentUserNpub != null && (hexCurrentUserNpub == hexPubkeyA);
        final bIsCurrentUser = currentUserNpub != null && (hexCurrentUserNpub == hexPubkeyB);

        // Current user always goes last
        if (aIsCurrentUser) return 1;
        if (bIsCurrentUser) return -1;

        // Admins come before regular members
        if (aIsAdmin && !bIsAdmin) return -1;
        if (!aIsAdmin && bIsAdmin) return 1;

        // Within same category (both admins or both regular), sort alphabetically
        final aName = a.displayName.isNotEmpty ? a.displayName : 'chats.unknownUser'.tr();
        final bName = b.displayName.isNotEmpty ? b.displayName : 'chats.unknownUser'.tr();
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
    final activeAccount = ref.read(activePubkeyProvider) ?? '';
    if (activeAccount.isNotEmpty) {
      final currentUserNpub = PubkeyFormatter(pubkey: activeAccount).toNpub();
      if (mounted) {
        setState(() {
          this.currentUserNpub = currentUserNpub;
        });
      }
    }
  }

  void _goToAddMembersScreen() {
    final existingMemberPubkeys = groupMembers.map((member) => member.publicKey).toList();
    
    Routes.goToAddGroupMembers(
      context,
      widget.groupId,
      existingMemberPubkeys,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupDetails = ref.watch(groupsProvider).groupsMap?[widget.groupId];
    final isAdmin = groupAdmins.any((admin) {
      if (currentUserNpub == null) {
        return false;
      }
      final hexAdminKey = PubkeyFormatter(pubkey: admin.publicKey).toHex();
      final hexCurrentUserKey = PubkeyFormatter(pubkey: currentUserNpub).toHex();
      return hexAdminKey == hexCurrentUserKey;
    });

    final groupDescription = groupDetails?.description ?? '';

    return SingleChildScrollView(
      child: Column(
        children: [
          Gap(64.h),
          WnAvatar(
            imageUrl: groupImagePath ?? '',
            displayName: groupDetails?.name ?? 'chats.unknownGroup'.tr(),
            size: 96.w,
            showBorder: true,
          ),
          SizedBox(height: 8.h),
          Text(
            groupDetails?.name ?? 'chats.unknownGroup'.tr(),
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.primary,
              fontSize: 18.sp,
            ),
          ),
          Gap(16.h),
          if (groupDescription.isNotEmpty) ...[
            Text(
              'chats.groupDescription'.tr(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.mutedForeground,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(4.h),
            Text(
              groupDetails?.description ?? '',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.primary,
                fontSize: 14.sp,
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: isAdmin ? () => Routes.goToEditGroup(context, widget.groupId) : null,
              child: Text(
                isAdmin ? 'chats.addGroupDescription'.tr() : 'chats.noGroupDescription'.tr(),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.mutedForeground,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (isAdmin) ...[
            Gap(24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  WnFilledButton(
                    size: WnButtonSize.small,
                    visualState: WnButtonVisualState.secondary,
                    label: 'ui.editGroup'.tr(),
                    onPressed: () => Routes.goToEditGroup(context, widget.groupId),
                  ),
                  Gap(8.h),
                  WnFilledButton(
                    size: WnButtonSize.small,
                    label: 'ui.addMembers'.tr(),
                    onPressed: () => _goToAddMembersScreen(),
                  ),
                ],
              ),
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
                    'chats.members'.tr(),
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.mutedForeground,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Gap(8.h),
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
    final isAdmin = groupAdmins.any((admin) {
      final hexAdminKey = PubkeyFormatter(pubkey: admin.publicKey).toHex();
      final hexMemberKey = PubkeyFormatter(pubkey: member.publicKey).toHex();
      return hexAdminKey == hexMemberKey;
    });
    final isCurrentUser =
        currentUserNpub != null &&
        PubkeyFormatter(pubkey: currentUserNpub).toHex() ==
            PubkeyFormatter(pubkey: member.publicKey).toHex();
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
            ? 'chats.you'.tr()
            : member.displayName.isNotEmpty
            ? member.displayName
            : 'chats.unknownUser'.tr(),
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 16.sp,
        ),
      ),
      subtitle:
          isAdmin
              ? Text(
                'chats.adminLabel'.tr(),
                style: TextStyle(
                  color: context.colors.mutedForeground,
                  fontSize: 12.sp,
                ),
              )
              : null,
    );
  }
}
