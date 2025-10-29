part of 'chat_info_screen.dart';

class DMChatInfo extends ConsumerWidget {
  const DMChatInfo({super.key, required this.groupId});
  final String groupId;

  Future<void> _toggleFollow(WidgetRef ref, String? pubkey, BuildContext context) async {
    if (pubkey == null) return;
    final groupsNotifier = ref.read(groupsProvider.notifier);
    final otherMember = groupsNotifier.getOtherGroupMember(groupId);
    final displayName = otherMember?.displayName ?? 'chats.unknown'.tr();

    final followNotifier = ref.read(followProvider(pubkey).notifier);
    var currentFollowState = ref.read(followProvider(pubkey));
    late String successMessage;

    if (currentFollowState.isFollowing) {
      successMessage = 'ui.unfollowed'.tr({'name': displayName});
      await followNotifier.removeFollow(pubkey);
    } else {
      successMessage = 'ui.followed'.tr({'name': displayName});
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

  void _copyToClipboard(WidgetRef ref, String pubkey) {
    final npub = PubkeyFormatter(pubkey: pubkey).toNpub();
    ClipboardUtils.copyWithToast(
      ref: ref,
      textToCopy: npub,
      successMessage: 'chats.publicKeyCopied'.tr(),
      noTextMessage: 'chats.noPublicKeyToCopy'.tr(),
    );
  }

  void _openAddToGroup(BuildContext context, String pubkey) {
    final npub = PubkeyFormatter(pubkey: pubkey).toNpub();
    context.push('/add_to_group/$npub');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    final otherMember =
        activePubkey.isNotEmpty
            ? ref.read(groupsProvider.notifier).getOtherGroupMember(groupId)
            : null;
    final otherUserPubkey = otherMember?.publicKey;

    final followState =
        otherUserPubkey != null ? ref.watch(followProvider(otherUserPubkey)) : const FollowState();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        children: [
          Gap(64.h),
          WnAvatar(
            imageUrl: otherMember?.imagePath ?? '',
            displayName: otherMember?.displayName ?? 'chats.unknown'.tr(),
            size: 96.w,
          ),
          SizedBox(height: 16.h),
          Text(
            otherMember?.displayName ?? 'chats.unknown'.tr(),
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.primary,
              fontSize: 18.sp,
            ),
          ),
          Gap(2.h),
          Text(
            otherMember?.nip05 ?? '',
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
                  otherMember?.publicKey.formatPublicKey() ?? '',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.mutedForeground,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              Gap(8.w),
              InkWell(
                onTap:
                    otherUserPubkey != null ? () => _copyToClipboard(ref, otherUserPubkey) : null,
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
              ref.read(chatSearchProvider(groupId).notifier).activateSearch();
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
            onPressed:
                followState.isLoading ? null : () => _toggleFollow(ref, otherUserPubkey, context),
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
            onPressed:
                otherUserPubkey != null ? () => _openAddToGroup(context, otherUserPubkey) : null,
          ),
        ],
      ),
    );
  }
}
