import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/polling_provider.dart';
import 'package:whitenoise/config/providers/profile_provider.dart';
import 'package:whitenoise/config/providers/profile_ready_card_provider.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/contact_list/new_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/services/welcome_notification_service.dart';
import 'package:whitenoise/ui/contact_list/widgets/chat_list_item_tile.dart';
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
  late final PollingNotifier _pollingNotifier;

  @override
  void initState() {
    super.initState();

    // Store reference to notifier early to avoid ref access in dispose
    _pollingNotifier = ref.read(pollingProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize welcome notification service
      WelcomeNotificationService.initialize(context);
      WelcomeNotificationService.setupWelcomeNotifications(ref);

      // Load initial data
      ref.read(welcomesProvider.notifier).loadWelcomes();
      ref.read(groupsProvider.notifier).loadGroups();
      ref.read(profileProvider.notifier).fetchProfileData();

      // Start polling for data updates
      _pollingNotifier.startPolling();
    });
  }

  @override
  void dispose() {
    // Use dispose method instead of stopPolling to avoid state modification during disposal
    _pollingNotifier.dispose();
    WelcomeNotificationService.clearContext();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch both groups and welcomes
    final groupList = ref.watch(groupsProvider.select((state) => state.groups)) ?? [];
    final welcomesList = ref.watch(welcomesProvider.select((state) => state.welcomes)) ?? [];
    final visibilityAsync = ref.watch(profileReadyCardVisibilityProvider);

    // Cache profile data to avoid unnecessary rebuilds
    final profileData = ref.watch(profileProvider);
    final currentUserName = profileData.valueOrNull?.displayName ?? '';
    final userFirstLetter =
        currentUserName.isNotEmpty == true ? currentUserName[0].toUpperCase() : '';
    final profileImagePath = profileData.valueOrNull?.picture ?? '';

    final chatItems = <ChatListItem>[];

    for (final group in groupList) {
      final lastMessage = ref.watch(
        chatProvider.select(
          (state) => state.getLatestMessageForGroup(group.mlsGroupId),
        ),
      );
      chatItems.add(
        ChatListItem.fromGroup(
          groupData: group,
          lastMessage: lastMessage,
        ),
      );
    }

    // Add pending welcomes as chat items
    final pendingWelcomes = welcomesList.where((welcome) => welcome.state == WelcomeState.pending);
    for (final welcome in pendingWelcomes) {
      chatItems.add(ChatListItem.fromWelcome(welcomeData: welcome));
    }

    // Sort by date created (most recent first)
    chatItems.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

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
                      profileImageUrl: profileImagePath,
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
              if (chatItems.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyGroupList(),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.only(top: 8.h, bottom: 32.h),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final item = chatItems[index];
                      return ChatListItemTile(item: item);
                    },
                    itemCount: chatItems.length,
                    separatorBuilder: (context, index) => Gap(8.w),
                  ),
                ),
            ],
          ),

          if (chatItems.isNotEmpty)
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

  /// Build profile avatar that properly reacts to account switches and uses metadata cache
  // Widget _buildProfileAvatar() {
  //   final activeAccountPubkey = ref.watch(activeAccountProvider);

  //   if (activeAccountPubkey == null) {
  //     // No active account, show fallback avatar
  //     return const ProfileAvatar();
  //   }

  //   // Use metadata cache to get contact model for current account
  //   return FutureBuilder(
  //     // This future will rebuild when activeAccountPubkey changes
  //     future: ref.read(metadataCacheProvider.notifier).getContactModel(activeAccountPubkey),
  //     builder: (context, snapshot) {
  //       if (snapshot.hasData) {
  //         final contactModel = snapshot.data!;
  //         final firstLetter =
  //             contactModel.displayNameOrName.isNotEmpty
  //                 ? contactModel.displayNameOrName[0].toUpperCase()
  //                 : null;

  //         return ProfileAvatar(
  //           profileImageUrl: contactModel.imagePath,
  //           userFirstLetter: firstLetter,
  //         );
  //       }

  //       // While loading or on error, show fallback with account-based letter
  //       final fallbackLetter =
  //           activeAccountPubkey.isNotEmpty
  //               ? activeAccountPubkey.substring(0, 1).toUpperCase()
  //               : null;

  //       return ProfileAvatar(
  //         userFirstLetter: fallbackLetter,
  //       );
  //     },
  //   );
  // }
}

class _EmptyGroupList extends StatelessWidget {
  const _EmptyGroupList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              AssetsPaths.icWhiteNoiseSvg,
              width: 69.17.w,
              height: 53.20.h,
              colorFilter: ColorFilter.mode(
                context.colors.primary,
                BlendMode.srcIn,
              ),
            ),
            Gap(12.h),
            Text(
              'Decentralized. Uncensorable.\nSecure Messaging.',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
