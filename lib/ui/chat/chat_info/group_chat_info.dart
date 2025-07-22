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
      _loadGroupData();
      _loadMembers();
      _loadCurrentUserNpub();
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

  Future<void> _loadCurrentUserNpub() async {
    final activeAccountData = ref.read(activeAccountProvider);
    if (activeAccountData != null) {
      final currentUserNpub = await npubFromHexPubkey(hexPubkey: activeAccountData);
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
          ContactAvatar(
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
    final isAdmin = groupAdmins.any((admin) => admin.publicKey == member.publicKey);
    final isCurrentUser = currentUserNpub != null && currentUserNpub == member.publicKey;
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
      leading: ContactAvatar(
        imageUrl: member.imagePath ?? '',
        displayName: member.name,
        size: 40.w,
        showBorder: true,
      ),
      title: Text(
        isCurrentUser
            ? 'You'
            : member.name.isNotEmpty
            ? member.name
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

class GroupMemberBottomSheet extends ConsumerStatefulWidget {
  const GroupMemberBottomSheet({
    super.key,
    required this.member,
    required this.groupId,
  });
  final User member;
  final String groupId;
  static void show(BuildContext context, {required String groupId, required User member}) {
    CustomBottomSheet.show(
      context: context,
      title: 'Member',

      builder: (context) => GroupMemberBottomSheet(groupId: groupId, member: member),
    );
  }

  @override
  ConsumerState<GroupMemberBottomSheet> createState() => _GroupMemberBottomSheetState();
}

class _GroupMemberBottomSheetState extends ConsumerState<GroupMemberBottomSheet> {
  String currentUserNpub = '';

  void _copyToClipboard() {
    final npub = widget.member.publicKey;
    if (npub.isEmpty) {
      ref.showErrorToast('No public key to copy');
      return;
    }
    Clipboard.setData(ClipboardData(text: npub));
    ref.showSuccessToast(
      'Public Key copied.',
    );
  }

  void _openAddToGroup() {
    if (widget.member.publicKey.isEmpty) {
      ref.showErrorToast('No user to add to group');
      return;
    }
    context.push('/add_to_group/${widget.member.publicKey}');
  }

  void _loadCurrentUserNpub() async {
    final activeAccount = ref.read(activeAccountProvider);
    if (activeAccount != null) {
      currentUserNpub = await activeAccount.toNpub() ?? '';
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUserNpub();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserIsAdmin =
        ref
            .watch(groupsProvider)
            .groupAdmins?[widget.groupId]
            ?.firstWhereOrNull(
              (admin) => admin.publicKey == currentUserNpub,
            ) !=
        null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Gap(16.h),
        ContactAvatar(
          imageUrl: widget.member.imagePath ?? '',
          displayName: widget.member.username,
          size: 96.w,
        ),
        Gap(4.h),
        Text(
          widget.member.username ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.member.nip05.isNotEmpty)
          Text(
            widget.member.nip05,
            style: TextStyle(
              color: context.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        Gap(16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  widget.member.publicKey.formatPublicKey(),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.mutedForeground,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              Gap(8.w),
              InkWell(
                onTap: _copyToClipboard,
                child: SvgPicture.asset(
                  AssetsPaths.icCopy,
                  width: 24.w,
                  height: 24.w,
                  colorFilter: ColorFilter.mode(
                    context.colors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ),
        Gap(32.h),
        if (currentUserIsAdmin)
          Column(
            children: [
              Row(
                spacing: 6.w,
                children: [
                  Flexible(
                    child: _SendMessageButton(widget.member),
                  ),
                  Flexible(
                    child: _AddToContactButton(widget.member),
                  ),
                ],
              ),
              // Gap(8.h),
              // AppFilledButton.child(
              //   onPressed: () {},
              //   size: AppButtonSize.small,
              //   visualState: AppButtonVisualState.secondary,
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Text(
              //         'Make Admin',
              //         style: context.textTheme.bodyMedium?.copyWith(
              //           color: context.colors.primary,
              //           fontWeight: FontWeight.w600,
              //           fontSize: 14.sp,
              //         ),
              //       ),
              //       Gap(8.w),
              //       SvgPicture.asset(
              //         AssetsPaths.icMakeAdmin,
              //         width: 14.w,
              //         height: 13.h,
              //         colorFilter: ColorFilter.mode(
              //           context.colors.primary,
              //           BlendMode.srcIn,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          )
        else
          _SendMessageButton(widget.member),
        Gap(8.h),
        AppFilledButton.child(
          onPressed: _openAddToGroup,
          size: AppButtonSize.small,
          visualState: AppButtonVisualState.secondary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Add to Another Group',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              Gap(8.w),
              SvgPicture.asset(
                AssetsPaths.icChatInvite,
                width: 14.w,
                height: 13.h,
                colorFilter: ColorFilter.mode(
                  context.colors.primary,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
        if (currentUserIsAdmin) ...[
          // Gap(8.h),
          // AppFilledButton.child(
          //   onPressed: () {},
          //   size: AppButtonSize.small,
          //   visualState: AppButtonVisualState.secondaryWarning,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Text(
          //         'Remove From Group',
          //         style: context.textTheme.bodyMedium?.copyWith(
          //           color: context.colors.destructive,
          //           fontWeight: FontWeight.w600,
          //           fontSize: 14.sp,
          //         ),
          //       ),
          //       Gap(8.w),
          //       SvgPicture.asset(
          //         AssetsPaths.icRemoveOutlined,
          //         width: 14.w,
          //         height: 13.h,
          //         colorFilter: ColorFilter.mode(
          //           context.colors.destructive,
          //           BlendMode.srcIn,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ] else ...[
          Gap(8.h),
          _AddToContactButton(widget.member),
        ],
      ],
    );
  }
}

class _SendMessageButton extends ConsumerStatefulWidget {
  const _SendMessageButton(this.user);
  final User user;
  @override
  ConsumerState<_SendMessageButton> createState() => __SendMessageButtonState();
}

class __SendMessageButtonState extends ConsumerState<_SendMessageButton> {
  final _logger = Logger('_SendMessageButtonState');
  bool _isCreatingGroup = false;
  bool get _isLoading => _isCreatingGroup;

  Future<void> _createOrOpenDirectMessageGroup() async {
    if (widget.user.publicKey.isEmpty) {
      ref.showErrorToast('No user to start chat with');
      return;
    }
    setState(() {
      _isCreatingGroup = true;
    });

    try {
      final groupData = await ref
          .read(groupsProvider.notifier)
          .createNewGroup(
            groupName: 'DM',
            groupDescription: 'Direct message',
            memberPublicKeyHexs: [widget.user.publicKey],
            adminPublicKeyHexs: [widget.user.publicKey],
          );

      if (groupData != null) {
        _logger.info('Direct message group created successfully: ${groupData.mlsGroupId}');

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context);
              context.navigateToGroupChatAndPopToHome(groupData);
            }
          });

          ref.showSuccessToast(
            'Chat with ${widget.user.username ?? widget.user.name} started successfully',
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

  @override
  Widget build(BuildContext context) {
    return AppFilledButton.child(
      onPressed: _createOrOpenDirectMessageGroup,
      loading: _isLoading,
      size: AppButtonSize.small,
      visualState: AppButtonVisualState.secondary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Send Message',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          Gap(4.w),
          SvgPicture.asset(
            AssetsPaths.icMessage,
            width: 14.w,
            height: 13.h,
            colorFilter: ColorFilter.mode(
              context.colors.primary,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}

// add contact
class _AddToContactButton extends ConsumerStatefulWidget {
  const _AddToContactButton(this.user);
  final User user;
  @override
  ConsumerState<_AddToContactButton> createState() => __AddToContactButtonState();
}

class __AddToContactButtonState extends ConsumerState<_AddToContactButton> {
  bool _isAddingContact = false;
  bool get _isLoading => _isAddingContact;
  bool _isContact() {
    final contactsState = ref.watch(contactsProvider);
    final contacts = contactsState.contactModels ?? [];

    // Check if the current user's pubkey exists in contacts
    return contacts.any(
      (contact) => contact.publicKey.toLowerCase() == widget.user.publicKey.toLowerCase(),
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
        await contactsNotifier.removeContactByHex(widget.user.publicKey);
        if (mounted) {
          ref.showSuccessToast('${widget.user.name} removed from contacts');
        }
      } else {
        await contactsNotifier.addContactByHex(widget.user.publicKey);
        if (mounted) {
          ref.showSuccessToast('${widget.user.name} added to contacts');
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

  @override
  Widget build(BuildContext context) {
    final isContact = _isContact();
    return AppFilledButton.child(
      onPressed: _toggleContact,
      loading: _isLoading,
      size: AppButtonSize.small,
      visualState: AppButtonVisualState.secondary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isContact ? 'Remove Contact' : 'Add Contact',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          Gap(4.w),
          SvgPicture.asset(
            isContact ? AssetsPaths.icRemoveUser : AssetsPaths.icAddUser,
            width: 13.w,
            height: 13.w,
            colorFilter: ColorFilter.mode(
              context.colors.primary,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
