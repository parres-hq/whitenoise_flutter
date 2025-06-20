import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../domain/dummy_data/dummy_chats.dart';
import '../../routing/routes.dart';
import '../core/themes/src/extensions.dart';
import 'widgets/chat_list_appbar.dart';
import 'widgets/chat_list_tile.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatListAppBar(
        onSettingsTap: () => context.push(Routes.settings),
      ),
      body: ColoredBox(
        color: context.colors.neutral,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: dummyChats.length,
          itemBuilder: (context, index) {
            final chat = dummyChats[index];
            return InkWell(
              onTap: () => context.push('${Routes.chats}/${chat.id}'),
              child: ChatListTile(chat: chat),
            );
          },
          separatorBuilder: (context, index) => Gap(8.h),
        ),
      ),
    );
  }
}
