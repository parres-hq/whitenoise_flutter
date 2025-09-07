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

  @override
  Widget build(BuildContext context) {
    final groupDetails = ref.watch(groupsProvider).groupsMap?[widget.groupId];
    ref.listen(groupsProvider, (previous, next) {
      _loadMembers();
    });

    return SingleChildScrollView(
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
          Gap(32.h),
          // TODO: Reenable when we have a search and mute features
          // Row(
          //   spacing: 12.w,
          //   children: [
          //     Expanded(
          //       child: WnFilledButton.icon(
          //         visualState: WnButtonVisualState.secondary,
          //         icon: SvgPicture.asset(
          //           AssetsPaths.icSearch,
          //           width: 14.w,
          //           colorFilter: ColorFilter.mode(context.colors.primary, BlendMode.srcIn),
          //         ),
          //         label: const Text('Search Chat'),
          //         onPressed: () {},
          //       ),
          //     ),
          //     Expanded(
          //       child: WnFilledButton.icon(
          //         visualState: WnButtonVisualState.secondary,
          //         icon: SvgPicture.asset(
          //           AssetsPaths.icMutedNotification,
          //           width: 14.w,
          //           colorFilter: ColorFilter.mode(context.colors.primary, BlendMode.srcIn),
          //         ),
          //         label: const Text('Mute Chat'),
          //         onPressed: () {},
          //       ),
          //     ),
          //   ],
          // ),
          // Gap(32.h),
          if (isLoadingMembers)
            const CircularProgressIndicator()
          else if (groupMembers.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 32.w),

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
