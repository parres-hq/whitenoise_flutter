import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../routing/routes.dart';
import '../core/themes/src/extensions.dart';
import 'widgets/chat_list_appbar.dart';

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64.w,
                color: context.colors.mutedForeground,
              ),
              Gap(16.h),
              Text(
                'No chats yet',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: context.colors.mutedForeground,
                ),
              ),
              Gap(8.h),
              Text(
                'Start a conversation with your contacts',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
