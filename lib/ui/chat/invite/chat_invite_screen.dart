import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/chat/widgets/contact_info.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';

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

    return Scaffold(
      backgroundColor: context.colors.neutral,
      appBar: CustomAppBar(
        title: ContactInfo(
          title: welcomeData.groupName,
          imageUrl: '',
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
            child: Column(
              children: [
                Icon(
                  Icons.group,
                  size: 64.r,
                  color: context.colors.primary,
                ),
                SizedBox(height: 16.h),
                Text(
                  welcomeData.groupName,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (welcomeData.groupDescription.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    welcomeData.groupDescription,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: context.colors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people,
                        size: 16.r,
                        color: context.colors.mutedForeground,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${welcomeData.memberCount} members',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Spacer to push buttons to bottom
          const Spacer(),

          // Accept/Decline buttons
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: context.colors.neutral,
              border: Border(
                top: BorderSide(
                  color: context.colors.border,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await welcomesNotifier.declineWelcomeInvitation(inviteId);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.destructive,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  ElevatedButton(
                    onPressed: () async {
                      await welcomesNotifier.acceptWelcomeInvitation(inviteId);
                      if (context.mounted) {
                        // Navigate to normal chat after accepting
                        Routes.goToChat(context, groupId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: context.colors.primaryForeground,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
