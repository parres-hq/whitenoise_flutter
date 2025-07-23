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
  bool isContact = false;
  bool isContactLoading = false;
  Future<DMChatData?>? _dmChatDataFuture;

  @override
  void initState() {
    super.initState();
    _dmChatDataFuture = ref.getDMChatData(widget.groupId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContact();
    });
  }

  @override
  void didUpdateWidget(DMChatInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _dmChatDataFuture = ref.getDMChatData(widget.groupId);
    }
  }

  Future<void> _loadContact() async {
    final activeAccountData = await ref.read(activeAccountProvider.notifier).getActiveAccountData();
    if (activeAccountData != null) {
      final currentUserNpub = await npubFromPublicKey(
        publicKey: await publicKeyFromString(publicKeyString: activeAccountData.pubkey),
      );
      final otherMember = ref
          .read(groupsProvider.notifier)
          .getOtherGroupMember(widget.groupId, currentUserNpub);
      if (otherMember != null && mounted) {
        otherUserNpub = otherMember.publicKey;
        _checkContactStatus(otherMember.publicKey);
      }
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

  void _copyToClipboard() {
    final npub = otherUserNpub ?? '';
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
    if (otherUserNpub == null) {
      ref.showErrorToast('No user to add to group');
      return;
    }
    context.push('/add_to_group/$otherUserNpub');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(contactsProvider, (previous, next) {
      if (otherUserNpub != null) {
        _checkContactStatus(otherUserNpub!);
      }
    });

    return FutureBuilder(
      future: _dmChatDataFuture,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final dmChatData = asyncSnapshot.data;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            children: [
              Gap(64.h),
              ContactAvatar(
                imageUrl: dmChatData?.displayImage ?? '',
                displayName: dmChatData?.displayName ?? 'Unknown',
                size: 96.w,
              ),
              SizedBox(height: 16.h),
              Text(
                dmChatData?.displayName ?? 'Unknown',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colors.primary,
                  fontSize: 18.sp,
                ),
              ),
              Gap(2.h),
              Text(
                dmChatData?.nip05 ?? '',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.mutedForeground,
                  fontSize: 14.sp,
                ),
              ),
              Gap(16.h),

              Row(
                children: [
                  Flexible(
                    child: Text(
                      dmChatData?.publicKey?.formatPublicKey() ?? '',
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
              Gap(32.h),
              AppFilledButton.icon(
                size: AppButtonSize.small,
                visualState: AppButtonVisualState.secondary,
                icon: const Text('Search Chat'),
                label: SvgPicture.asset(
                  AssetsPaths.icSearch,
                  width: 14.w,
                  colorFilter: ColorFilter.mode(
                    context.colors.secondaryForeground,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () {
                  // Activate search using the provider
                  ref.read(chatSearchProvider(widget.groupId).notifier).activateSearch();
                  context.pop(); // Close the chat info screen
                },
              ),

              Gap(12.h),
              AppFilledButton.icon(
                size: AppButtonSize.small,
                visualState:
                    isContact ? AppButtonVisualState.secondary : AppButtonVisualState.primary,
                icon: Text(isContact ? 'Remove Contact' : 'Add Contact'),
                label:
                    isContactLoading
                        ? SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                isContact
                                    ? context.colors.secondaryForeground
                                    : context.colors.primaryForeground,
                          ),
                        )
                        : SvgPicture.asset(
                          isContact ? AssetsPaths.icRemoveUser : AssetsPaths.icAddUser,
                          width: 14.w,
                          colorFilter: ColorFilter.mode(
                            isContact
                                ? context.colors.secondaryForeground
                                : context.colors.primaryForeground,
                            BlendMode.srcIn,
                          ),
                        ),
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
              AppFilledButton.icon(
                size: AppButtonSize.small,
                visualState: AppButtonVisualState.secondary,
                icon: const Text('Add to Group'),
                label: SvgPicture.asset(
                  AssetsPaths.icAdd,
                  width: 14.w,
                  colorFilter: ColorFilter.mode(
                    context.colors.secondaryForeground,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: _openAddToGroup,
              ),

              Gap(12.h),
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
            ],
          ),
        );
      },
    );
  }
}
