import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/contact_list/new_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/group_list_tile.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupsProvider.notifier).loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupList = ref.watch(groupsProvider).groups ?? [];

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CustomAppBar.sliver(
                title: InkWell(
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: () => context.push(Routes.settings),
                  child: ContactAvatar(
                    imgPath: '',
                    size: 36.r,
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
                SliverPadding(
                  padding: EdgeInsets.only(top: 8.h, bottom: 32.h),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final group = groupList[index];
                      return GroupListTile(group: group);
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
    );
  }
}

class _EmptyGroupList extends StatelessWidget {
  const _EmptyGroupList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64.w,
            color: context.colors.primary,
          ),
          Gap(16.h),
          Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: context.colors.primary,
            ),
          ),
          Gap(8.h),
          Text(
            'Start a conversation with your contacts',
            style: TextStyle(
              fontSize: 14.sp,
              color: context.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
