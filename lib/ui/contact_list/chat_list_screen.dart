import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/profile_provider.dart';
import 'package:whitenoise/config/providers/profile_ready_card_provider.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/contact_list/new_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/services/welcome_notification_service.dart';
import 'package:whitenoise/ui/contact_list/widgets/group_list_tile.dart';
import 'package:whitenoise/ui/contact_list/widgets/profile_avatar.dart';
import 'package:whitenoise/ui/contact_list/widgets/profile_ready_card.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/bottom_fade.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _profileImagePath = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize welcome notification service
      WelcomeNotificationService.initialize(context);
      WelcomeNotificationService.setupWelcomeNotifications(ref);

      // Load data (welcomes loading will trigger callbacks if new ones exist)
      ref.read(welcomesProvider.notifier).loadWelcomes();
      ref.read(groupsProvider.notifier).loadGroups();
      _loadProfileData();
    });
  }

  @override
  void dispose() {
    // Clear welcome notifications when screen is disposed
    WelcomeNotificationService.clearContext();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      await ref.read(profileProvider.notifier).fetchProfileData();

      final profileData = ref.read(profileProvider);

      profileData.whenData((profile) {
        setState(() {
          _profileImagePath = profile.picture ?? '';
        });
      });
    } catch (e) {
      // Handle error silently for avatar
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupList = ref.watch(groupsProvider).groups ?? [];
    final visibilityAsync = ref.watch(profileReadyCardVisibilityProvider);
    ref.watch(profileProvider);
    final currentUserName = ref.watch(profileProvider).valueOrNull?.displayName ?? '';
    final userFirstLetter =
        currentUserName.isNotEmpty == true ? currentUserName[0].toUpperCase() : '';

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CustomAppBar.sliver(
                title: Padding(
                  padding: EdgeInsets.only(left: 16.w),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16.r),
                    onTap: () => context.push(Routes.settings),
                    child: ProfileAvatar(
                      profileImageUrl: _profileImagePath,
                      userFirstLetter: userFirstLetter,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => NewChatBottomSheet.show(context),
                    icon: Image.asset(
                      AssetsPaths.icAddNewChat,
                      width: 32.w,
                      height: 32.w,
                    ),
                  ),
                  Gap(8.w),
                ],
                pinned: true,
                floating: true,
              ),
              if (groupList.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyGroupList(),
                )
              else
                ...[],
              SliverPadding(
                padding: EdgeInsets.only(top: 8.h, bottom: 32.h),
                sliver: SliverList.separated(
                  itemBuilder: (context, index) {
                    final group = groupList[index];
                    final lastMessage = ref
                        .watch(chatProvider.notifier)
                        .getLatestMessageForGroup(group.mlsGroupId);
                    return GroupListTile(
                      group: group,
                      lastMessage: lastMessage,
                    );
                  },
                  itemCount: groupList.length,
                  separatorBuilder: (context, index) => Gap(8.w),
                ),
              ),
            ],
          ),

          if (groupList.isNotEmpty)
            Positioned(bottom: 0, left: 0, right: 0, height: 54.h, child: const BottomFade()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: visibilityAsync.when(
          data: (showCard) => showCard ? const ProfileReadyCard() : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _EmptyGroupList extends StatelessWidget {
  const _EmptyGroupList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Text(
          'Welcome to White Noise. Private, secure,\ndecentralized, uncensorable messaging where your identity stays yours.',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
