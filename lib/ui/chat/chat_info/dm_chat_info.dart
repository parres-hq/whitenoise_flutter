part of 'chat_info_screen.dart';

class DMChatInfo extends ConsumerStatefulWidget {
  const DMChatInfo({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<DMChatInfo> createState() => _DMChatInfoState();
}

class _DMChatInfoState extends ConsumerState<DMChatInfo> {
  Future<DMChatData?>? _dmChatDataFuture;

  @override
  void initState() {
    super.initState();
    _dmChatDataFuture = ref.getDMChatData(widget.groupId);
  }

  @override
  void didUpdateWidget(DMChatInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _dmChatDataFuture = ref.getDMChatData(widget.groupId);
    }
  }

  Future<void> _toggleFollow(String? pubkey) async {
    if (pubkey == null) return;
    final dmChatData = await _dmChatDataFuture;
    final displayName = dmChatData?.displayName ?? 'chats.unknown'.tr();

    final followNotifier = ref.read(followProvider(pubkey).notifier);
    var currentFollowState = ref.read(followProvider(pubkey));
    late String successMessage;

    if (currentFollowState.isFollowing) {
      successMessage = 'ui.unfollowed'.tr().replaceAll('{name}', displayName);
      await followNotifier.removeFollow(pubkey);
    } else {
      successMessage = 'ui.followed'.tr().replaceAll('{name}', displayName);
      await followNotifier.addFollow(pubkey);
    }

    currentFollowState = ref.read(followProvider(pubkey));
    final errorMessage = currentFollowState.error ?? '';
    if (errorMessage.isNotEmpty) {
      ref.showErrorToast(errorMessage);
    } else {
      ref.showSuccessToast(successMessage);
    }
  }

  void _copyToClipboard(String pubkey) {
    final npub = PubkeyFormatter(pubkey: pubkey).toNpub();
    ClipboardUtils.copyWithToast(
      ref: ref,
      textToCopy: npub,
      successMessage: 'chats.publicKeyCopied'.tr(),
      noTextMessage: 'chats.noPublicKeyToCopy'.tr(),
    );
  }

  void _openAddToGroup(String pubkey) {
    final npub = PubkeyFormatter(pubkey: pubkey).toNpub();
    context.push('/add_to_group/$npub');
  }

  @override
  Widget build(BuildContext context) {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    final otherMember =
        activePubkey.isNotEmpty
            ? ref.read(groupsProvider.notifier).getOtherGroupMember(widget.groupId)
            : null;
    final otherUserPubkey = otherMember?.publicKey;

    final followState =
        otherUserPubkey != null ? ref.watch(followProvider(otherUserPubkey)) : const FollowState();

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
              WnAvatar(
                imageUrl: dmChatData?.displayImage ?? '',
                displayName: dmChatData?.displayName ?? 'chats.unknown'.tr(),
                size: 96.w,
              ),
              SizedBox(height: 16.h),
              Text(
                dmChatData?.displayName ?? 'chats.unknown'.tr(),
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
                    onTap: otherUserPubkey != null ? () => _copyToClipboard(otherUserPubkey) : null,
                    child: WnImage(
                      AssetsPaths.icCopy,
                      width: 24.w,
                      height: 24.w,
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
              Gap(32.h),
              WnFilledButton(
                size: WnButtonSize.small,
                visualState: WnButtonVisualState.secondary,
                label: 'ui.searchChat'.tr(),
                suffixIcon: WnImage(
                  AssetsPaths.icSearch,
                  width: 14.w,
                  color: context.colors.secondaryForeground,
                ),
                onPressed: () {
                  ref.read(chatSearchProvider(widget.groupId).notifier).activateSearch();
                  context.pop();
                },
              ),
              Gap(8.h),
              WnFilledButton(
                size: WnButtonSize.small,
                visualState:
                    followState.isFollowing
                        ? WnButtonVisualState.secondary
                        : WnButtonVisualState.primary,
                label: followState.isFollowing ? 'ui.unfollow'.tr() : 'ui.follow'.tr(),
                loading: followState.isLoading,
                suffixIcon: WnImage(
                  followState.isFollowing ? AssetsPaths.icRemoveUser : AssetsPaths.icAddUser,
                  width: 14.w,
                  color:
                      followState.isFollowing
                          ? context.colors.secondaryForeground
                          : context.colors.primaryForeground,
                ),
                onPressed: followState.isLoading ? null : () => _toggleFollow(otherUserPubkey),
              ),
              Gap(8.h),
              WnFilledButton(
                size: WnButtonSize.small,
                visualState: WnButtonVisualState.secondary,
                label: 'ui.addToGroup'.tr(),
                suffixIcon: WnImage(
                  AssetsPaths.icAdd,
                  width: 14.w,
                  color: context.colors.secondaryForeground,
                ),
                onPressed: otherUserPubkey != null ? () => _openAddToGroup(otherUserPubkey) : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
