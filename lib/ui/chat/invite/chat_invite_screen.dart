import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/chat/widgets/contact_info.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class ChatInviteScreen extends ConsumerWidget {
  final String groupId;
  final String inviteId;

  const ChatInviteScreen({
    super.key,
    required this.groupId,
    required this.inviteId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final welcomesNotifier = ref.read(welcomesProvider.notifier);
    final welcomeData = welcomesNotifier.getWelcomeById(inviteId);
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
      appBar: CustomAppBar(
        title:
            isDMInvite
                ? _buildDMAppBarTitle(ref, welcomeData)
                : ContactInfo(
                  title: welcomeData.groupName,
                  imageUrl: '',
                ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInviteHeader(context, ref, welcomeData),
          const Spacer(),
          Container(
            padding: EdgeInsets.all(24.w),

            child: SafeArea(
              child: Column(
                children: [
                  AppFilledButton(
                    title: 'Decline',
                    visualState: AppButtonVisualState.secondary,
                    onPressed: () async {
                      await welcomesNotifier.declineWelcomeInvitation(inviteId);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  Gap(8.h),
                  AppFilledButton(
                    title: 'Accept',
                    onPressed: () async {
                      try {
                        final success = await welcomesNotifier.acceptWelcomeInvitation(inviteId);
                        if (success && context.mounted) {
                          final groupsNotifier = ref.read(groupsProvider.notifier);
                          await groupsNotifier.loadGroups();
                          await Future.delayed(const Duration(milliseconds: 1000));
                          if (context.mounted) {
                            context.pushReplacement('/chats/$groupId');
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error accepting invitation: $e'),
                            ),
                          );
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

  Widget _buildInviteHeader(BuildContext context, WidgetRef ref, WelcomeData welcomeData) {
    final isDMInvite = welcomeData.memberCount <= 2;

    if (isDMInvite) {
      return _buildDMInviteHeader(context, ref, welcomeData);
    } else {
      return _buildGroupInviteHeader(context, ref, welcomeData);
    }
  }

  Widget _buildGroupInviteHeader(BuildContext context, WidgetRef ref, WelcomeData welcomeData) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Gap(32.h),
          ContactAvatar(
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

  Widget _buildDMInviteHeader(BuildContext context, WidgetRef ref, WelcomeData welcomeData) {
    final metadataCacheNotifier = ref.read(metadataCacheProvider.notifier);

    return FutureBuilder(
      future: metadataCacheNotifier.getContactModel(welcomeData.welcomer),
      builder: (context, snapshot) {
        final welcomerContact = snapshot.data;
        final welcomerName = welcomerContact?.displayNameOrName ?? 'Unknown User';
        final welcomerImageUrl = welcomerContact?.imagePath ?? '';

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Gap(32.h),
              ContactAvatar(
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

  Widget _buildDMAppBarTitle(WidgetRef ref, WelcomeData welcomeData) {
    final metadataCacheNotifier = ref.read(metadataCacheProvider.notifier);

    return FutureBuilder(
      future: metadataCacheNotifier.getContactModel(welcomeData.welcomer),
      builder: (context, snapshot) {
        final welcomerContact = snapshot.data;
        final welcomerName = welcomerContact?.displayNameOrName ?? 'Unknown User';
        final welcomerImageUrl = welcomerContact?.imagePath ?? '';

        return ContactInfo(
          title: welcomerName,
          imageUrl: welcomerImageUrl,
        );
      },
    );
  }
}
