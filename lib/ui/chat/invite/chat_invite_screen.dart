import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/chat/widgets/user_profile_info.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class ChatInviteScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String inviteId;

  const ChatInviteScreen({
    super.key,
    required this.groupId,
    required this.inviteId,
  });

  @override
  ConsumerState<ChatInviteScreen> createState() => _ChatInviteScreenState();
}

class _ChatInviteScreenState extends ConsumerState<ChatInviteScreen> {
  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    final welcomesNotifier = ref.watch(welcomesProvider.notifier);
    final welcome = welcomesNotifier.getWelcomeById(widget.inviteId);
    if (welcome == null) {
      return Scaffold(
        backgroundColor: context.colors.neutral,
        body: Center(
          child: Text('ui.invitationNotFound'.tr()),
        ),
      );
    }

    final isDMInvite = welcome.memberCount <= 2;

    return Scaffold(
      backgroundColor: context.colors.neutral,
      appBar: WnAppBar(
        title:
            isDMInvite
                ? WelcomeAppbar(welcome: welcome)
                : ChatGroupAppbar(
                  groupId: widget.groupId,
                ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InviteHeader(welcome: welcome),
          const Spacer(),
          Container(
            padding: EdgeInsets.all(24.w),

            child: SafeArea(
              child: Column(
                children: [
                  WnFilledButton(
                    label: 'shared.decline'.tr(),
                    visualState: WnButtonVisualState.secondary,
                    onPressed: () async {
                      await welcomesNotifier.declineWelcomeInvitation(widget.inviteId);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  Gap(8.h),
                  WnFilledButton(
                    label: 'shared.accept'.tr(),
                    loading: _isAccepting,
                    onPressed:
                        _isAccepting
                            ? null
                            : () async {
                              setState(() {
                                _isAccepting = true;
                              });
                              try {
                                final success = await welcomesNotifier.acceptWelcomeInvitation(
                                  widget.inviteId,
                                );
                                if (success && context.mounted) {
                                  final groupsNotifier = ref.read(groupsProvider.notifier);
                                  await groupsNotifier.loadGroups();
                                  await Future.delayed(const Duration(milliseconds: 1000));
                                  if (context.mounted) {
                                    context.pushReplacement('/chats/${widget.groupId}');
                                  }
                                }
                              } catch (e) {
                                ref
                                    .read(toastMessageProvider.notifier)
                                    .showError('Error accepting invitation: $e');
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isAccepting = false;
                                  });
                                }
                              }
                            },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InviteHeader extends ConsumerWidget {
  final Welcome welcome;

  const InviteHeader({
    super.key,
    required this.welcome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDMInvite = welcome.memberCount <= 2;

    if (isDMInvite) {
      return DMInviteHeader(welcome: welcome);
    } else {
      return GroupInviteHeader(welcome: welcome);
    }
  }
}

class GroupInviteHeader extends StatelessWidget {
  final Welcome welcome;

  const GroupInviteHeader({
    super.key,
    required this.welcome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Gap(32.h),
          WnAvatar(
            imageUrl: '',
            displayName: welcome.groupName,
            size: 96.r,
            pubkey: welcome.nostrGroupId,
            showBorder: true,
          ),
          Gap(12.h),
          Text(
            welcome.groupName,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
          Gap(12.h),
          if (welcome.groupDescription.isNotEmpty) ...[
            Text(
              'ui.groupDescription'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.mutedForeground,
              ),
            ),
            Gap(4.h),
            Text(
              welcome.groupDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.colors.primary,
              ),
            ),
            Gap(16.h),
          ],
          Text.rich(
            TextSpan(
              text: 'ui.groupChatInvitation'.tr(),
              style: TextStyle(
                fontSize: 14.sp,
                color: context.colors.mutedForeground,
              ),
              children: [
                TextSpan(
                  text: 'ui.membersCount'.tr({'count': welcome.memberCount}),
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Gap(32.h),
        ],
      ),
    );
  }
}

class DMInviteHeader extends ConsumerWidget {
  final Welcome welcome;

  const DMInviteHeader({
    super.key,
    required this.welcome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch cached welcomer user data from welcomes provider
    final welcomerUser = ref.watch(
      welcomesProvider.select((s) => s.welcomerUsers?[welcome.welcomer]),
    );

    // Show nothing while waiting for data to load
    if (welcomerUser == null) {
      return const SizedBox.shrink();
    }

    final welcomerName = welcomerUser.displayName;
    final welcomerNpub =
        PubkeyFormatter(pubkey: welcomerUser.publicKey).toNpub()?.formatPublicKey();
    final welcomerPubkey = welcomerUser.publicKey;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Gap(32.h),
          WnAvatar(
            imageUrl: welcomerUser.imagePath ?? '',
            displayName: welcomerName,
            size: 96.r,
            showBorder: true,
            pubkey: welcomerPubkey,
          ),
          Gap(12.h),
          Text(
            welcomerName,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
          Gap(4.h),
          if ((welcomerUser.nip05).isNotEmpty)
            Text(
              welcomerUser.nip05,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.colors.mutedForeground,
              ),
            ),
          Gap(12.h),
          Text(
            welcomerNpub ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: context.colors.mutedForeground,
            ),
          ),
          Gap(32.h),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$welcomerName ',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: 'ui.invitedYouToSecureChat'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.colors.mutedForeground,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          Gap(32.h),
        ],
      ),
    );
  }
}

class WelcomeAppbar extends ConsumerWidget {
  final Welcome welcome;

  const WelcomeAppbar({
    super.key,
    required this.welcome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch cached welcomer user data from welcomes provider
    final welcomerUser = ref.watch(
      welcomesProvider.select((s) => s.welcomerUsers?[welcome.welcomer]),
    );

    // Show nothing while waiting for data to load
    if (welcomerUser == null) {
      return const SizedBox.shrink();
    }
    final welcomerPubkey = welcomerUser.publicKey;

    return Row(
      children: [
        WnAvatar(
          imageUrl: welcomerUser.imagePath ?? '',
          displayName: welcomerUser.displayName,
          size: 36.r,
          showBorder: true,
          pubkey: welcomerPubkey,
        ),
        Gap(8.w),
        Expanded(
          child: Text(
            welcomerUser.displayName,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.solidPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
