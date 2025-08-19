import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/chat/widgets/contact_info.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
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
    final welcomeData = welcomesNotifier.getWelcomeById(widget.inviteId);
    if (welcomeData == null) {
      return Scaffold(
        backgroundColor: context.colors.neutral,
        body: const Center(
          child: Text('Invitation not found'),
        ),
      );
    }

    final isDMInvite = welcomeData.memberCount <= 2;

    return Scaffold(
      backgroundColor: context.colors.neutral,
      appBar: WnAppBar(
        title:
            isDMInvite
                ? DMAppBarTitle(welcomeData: welcomeData)
                : ContactInfo(
                  title: welcomeData.groupName,
                  image: '',
                ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InviteHeader(welcomeData: welcomeData),
          const Spacer(),
          Container(
            padding: EdgeInsets.all(24.w),

            child: SafeArea(
              child: Column(
                children: [
                  WnFilledButton(
                    label: 'Decline',
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
                    label: 'Accept',
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
  final WelcomeData welcomeData;

  const InviteHeader({
    super.key,
    required this.welcomeData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDMInvite = welcomeData.memberCount <= 2;

    if (isDMInvite) {
      return DMInviteHeader(welcomeData: welcomeData);
    } else {
      return GroupInviteHeader(welcomeData: welcomeData);
    }
  }
}

class GroupInviteHeader extends StatelessWidget {
  final WelcomeData welcomeData;

  const GroupInviteHeader({
    super.key,
    required this.welcomeData,
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
            displayName: welcomeData.groupName,
            size: 96.r,
            showBorder: true,
          ),
          Gap(12.h),
          Text(
            welcomeData.groupName,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
          Gap(16.h),
          FutureBuilder(
            future: npubFromHexPubkey(hexPubkey: welcomeData.nostrGroupId),
            builder: (context, asyncSnapshot) {
              final groupNpub = asyncSnapshot.data ?? '';
              return Text(
                groupNpub.formatPublicKey(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                ),
              );
            },
          ),
          Gap(12.h),
          if (welcomeData.groupDescription.isNotEmpty) ...[
            Text(
              'Group Description:',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.mutedForeground,
              ),
            ),
            Gap(4.h),
            Text(
              welcomeData.groupDescription,
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
              text: 'Group Chat Invitation • ',
              style: TextStyle(
                fontSize: 14.sp,
                color: context.colors.mutedForeground,
              ),
              children: [
                TextSpan(
                  text: '${welcomeData.memberCount} members',
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
  final WelcomeData welcomeData;

  const DMInviteHeader({
    super.key,
    required this.welcomeData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadataCacheNotifier = ref.read(metadataCacheProvider.notifier);

    return FutureBuilder(
      future: metadataCacheNotifier.getContactModel(welcomeData.welcomer),
      builder: (context, snapshot) {
        final welcomerContact = snapshot.data;
        final welcomerName = welcomerContact?.displayName ?? 'Unknown User';
        final welcomerImageUrl = welcomerContact?.imagePath ?? '';

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Gap(32.h),
              WnAvatar(
                imageUrl: welcomerImageUrl,
                displayName: welcomerName,
                size: 96.r,
                showBorder: true,
              ),
              Gap(12.h),
              Text(
                welcomerName.capitalizeFirst,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
              Gap(4.h),
              Text(
                welcomerContact?.nip05 ?? '',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                ),
              ),
              Gap(12.h),
              FutureBuilder(
                future: npubFromHexPubkey(hexPubkey: welcomeData.welcomer),
                builder: (context, asyncSnapshot) {
                  final welcomerNpub = asyncSnapshot.data ?? '';
                  return Text(
                    welcomerNpub.formatPublicKey(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.colors.mutedForeground,
                    ),
                  );
                },
              ),
              Gap(32.h),
              Text.rich(
                TextSpan(
                  text: welcomerName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: ' invited you to a secure chat.',
                      style: TextStyle(
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
      },
    );
  }
}

class DMAppBarTitle extends ConsumerWidget {
  final WelcomeData welcomeData;

  const DMAppBarTitle({
    super.key,
    required this.welcomeData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadataCacheNotifier = ref.read(metadataCacheProvider.notifier);

    return FutureBuilder(
      future: metadataCacheNotifier.getContactModel(welcomeData.welcomer),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (isLoading) {
          return const ContactInfo.loading();
        }

        final welcomerContact = snapshot.data;
        final welcomerName = welcomerContact?.displayName ?? 'Unknown User';
        final welcomerImageUrl = welcomerContact?.imagePath ?? '';

        return ContactInfo(
          title: welcomerName,
          image: welcomerImageUrl,
        );
      },
    );
  }
}
