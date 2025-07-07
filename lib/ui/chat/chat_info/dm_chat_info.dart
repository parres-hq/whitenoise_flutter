part of 'chat_info_screen.dart';

class DMChatInfo extends ConsumerStatefulWidget {
  const DMChatInfo({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<DMChatInfo> createState() => _DMChatInfoState();
}

class _DMChatInfoState extends ConsumerState<DMChatInfo> {
  final _logger = Logger('DMChatInfo');
  String? otherUserNpub;
  String? otherUserNip05;
  String? otherUserImagePath;
  bool isContact = false;
  bool isContactLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDMData();
    });
  }

  Future<void> _loadDMData() async {
    final activeAccountData = await ref.read(activeAccountProvider.notifier).getActiveAccountData();
    if (activeAccountData != null) {
      final currentUserNpub = await npubFromPublicKey(
        publicKey: await publicKeyFromString(publicKeyString: activeAccountData.pubkey),
      );
      final otherMember = ref
          .read(groupsProvider.notifier)
          .getOtherGroupMember(widget.groupId, currentUserNpub);
      if (otherMember != null && mounted) {
        setState(() {
          otherUserNpub = otherMember.publicKey;
          otherUserNip05 = otherMember.nip05;
          otherUserImagePath = otherMember.imagePath;
        });

        _checkContactStatus(otherMember.publicKey);

        if (otherMember.nip05.isEmpty) {
          _fetchUserMetadata(otherMember.publicKey);
        }
      }
    }
  }

  Future<void> _fetchUserMetadata(String userNpub) async {
    try {
      final publicKey = await publicKeyFromString(publicKeyString: userNpub);
      final metadata = await fetchMetadata(pubkey: publicKey);
      if (metadata != null && mounted) {
        setState(() {
          otherUserNip05 = metadata.nip05;
          // Update image path if we got fresh metadata
          if (metadata.picture != null) {
            otherUserImagePath = metadata.picture;
          }
        });
      }
    } catch (e) {
      _logger.warning('Error fetching user metadata: $e');
    }
  }

  void _checkContactStatus(String userNpub) {
    final contacts = ref.read(contactsProvider).contactModels ?? [];
    final isUserContact = contacts.any((contact) => contact.publicKey == userNpub);
    if (mounted) {
      setState(() {
        isContact = isUserContact;
      });
    }
  }

  Future<void> _addContact() async {
    if (otherUserNpub == null) return;

    setState(() {
      isContactLoading = true;
    });

    try {
      await ref.read(contactsProvider.notifier).addContactByHex(otherUserNpub!);
      if (mounted) {
        setState(() {
          isContact = true;
        });
      }
    } catch (e) {
      _logger.warning('Error adding contact: $e');
    } finally {
      if (mounted) {
        setState(() {
          isContactLoading = false;
        });
      }
    }
  }

  Future<void> _removeContact() async {
    if (otherUserNpub == null) return;

    setState(() {
      isContactLoading = true;
    });

    try {
      await ref.read(contactsProvider.notifier).removeContactByHex(otherUserNpub!);
      if (mounted) {
        setState(() {
          isContact = false;
        });
      }
    } catch (e) {
      _logger.warning('Error removing contact: $e');
    } finally {
      if (mounted) {
        setState(() {
          isContactLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = ref.watch(groupsProvider).groupDisplayNames?[widget.groupId];

    ref.listen(contactsProvider, (previous, next) {
      if (otherUserNpub != null) {
        _checkContactStatus(otherUserNpub!);
      }
    });

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        children: [
          Gap(64.h),
          ContactAvatar(
            imageUrl: otherUserImagePath ?? '',
            size: 96.w,
          ),
          SizedBox(height: 16.h),
          Text(
            displayName ?? 'Unknown',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.primary,
              fontSize: 18.sp,
            ),
          ),
          Gap(2.h),
          if (otherUserNip05 != null && otherUserNip05!.isNotEmpty)
            Text(
              otherUserNip05!,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.mutedForeground,
                fontSize: 14.sp,
              ),
            ),
          Gap(16.h),
          if (otherUserNpub != null)
            Text(
              otherUserNpub!.formatPublicKey(),
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.mutedForeground,
                fontSize: 14.sp,
              ),
            ),
          Gap(32.h),
          AppFilledButton.icon(
            visualState:
                isContact ? AppButtonVisualState.secondaryWarning : AppButtonVisualState.primary,
            icon:
                isContactLoading
                    ? SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.primaryForeground,
                      ),
                    )
                    : SvgPicture.asset(
                      isContact ? AssetsPaths.icRemoveUser : AssetsPaths.icAddUser,
                      width: 14.w,
                      colorFilter: ColorFilter.mode(
                        isContact ? context.colors.destructive : context.colors.primaryForeground,
                        BlendMode.srcIn,
                      ),
                    ),
            label: Text(isContact ? 'Remove Contact' : 'Add Contact'),
            onPressed:
                isContactLoading
                    ? null
                    : () {
                      if (isContact) {
                        _removeContact();
                      } else {
                        _addContact();
                      }
                    },
          ),
          Gap(12.h),
          Row(
            spacing: 12.w,
            children: [
              Expanded(
                child: AppFilledButton.icon(
                  visualState: AppButtonVisualState.secondary,
                  icon: SvgPicture.asset(
                    AssetsPaths.icSearch,
                    width: 14.w,
                    colorFilter: ColorFilter.mode(context.colors.primary, BlendMode.srcIn),
                  ),
                  label: const Text('Search Chat'),
                  onPressed: () {},
                ),
              ),
              Expanded(
                child: AppFilledButton.icon(
                  visualState: AppButtonVisualState.secondary,
                  icon: SvgPicture.asset(
                    AssetsPaths.icMutedNotification,
                    width: 14.w,
                    colorFilter: ColorFilter.mode(context.colors.primary, BlendMode.srcIn),
                  ),
                  label: const Text('Mute Chat'),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
