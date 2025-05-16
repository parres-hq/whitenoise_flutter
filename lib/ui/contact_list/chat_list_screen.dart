import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/domain/dummy_data/dummy_chats.dart';
import 'package:whitenoise/ui/contact_list/widgets/chat_list_appbar.dart';
import 'package:whitenoise/ui/contact_list/widgets/chat_list_tile.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatListAppBar(),
      body: ColoredBox(
        color: AppColors.white,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: dummyChats.length,
          itemBuilder: (context, index) {
            final chat = dummyChats[index];
            return ChatListTile(chat: chat);
          },
          separatorBuilder: (context, index) => Gap(8.h),
        ),
      ),
    );
  }
}
