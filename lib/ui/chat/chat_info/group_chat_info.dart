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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupData();
      _loadMembers();
    });
  }

  Future<void> _loadGroupData() async {
    final groupDetails = ref.read(groupsProvider).groupsMap?[widget.groupId];
    if (groupDetails?.nostrGroupId != null) {
      try {
        final npub = await npubFromPublicKey(
          publicKey: await publicKeyFromString(publicKeyString: groupDetails!.nostrGroupId),
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

  @override
  Widget build(BuildContext context) {
    final groupDetails = ref.watch(groupsProvider).groupsMap?[widget.groupId];

    ref.listen(groupsProvider, (previous, next) {
      _loadMembers();
    });

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Gap(64.h),
            ContactAvatar(
              imageUrl: '',
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
            //       child: AppFilledButton.icon(
            //         visualState: AppButtonVisualState.secondary,
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
            //       child: AppFilledButton.icon(
            //         visualState: AppButtonVisualState.secondary,
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
                  Text(
                    'Members:',
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.mutedForeground,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap(16.h),
                  ...groupMembers.map((member) => _buildMemberListTile(member)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberListTile(User member) {
    final isAdmin = groupAdmins.any((admin) => admin.publicKey == member.publicKey);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ContactAvatar(
        imageUrl: member.imagePath ?? '',
        displayName: member.name,
        size: 40.w,
        showBorder: true,
      ),
      title: Text(
        member.name.isNotEmpty ? member.name : 'Unknown User',
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
