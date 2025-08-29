import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/chat_search_provider.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/dm_chat_data.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/domain/services/dm_chat_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/chat/chat_info/widgets/group_member_bottom_sheet.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';
import 'package:whitenoise/utils/string_extensions.dart';

part 'dm_chat_info.dart';
part 'group_chat_info.dart';

class ChatInfoScreen extends ConsumerStatefulWidget {
  const ChatInfoScreen({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends ConsumerState<ChatInfoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupsProvider.notifier).loadGroupDetails(widget.groupId);
      _loadFollows();
    });
  }

  Future<void> _loadFollows() async {
    try {
      final activeAccountState = await ref.read(activeAccountProvider.future);
      final activeAccount = activeAccountState.account;
      if (activeAccount != null) {
        await ref.read(followsProvider.notifier).loadFollows();
      }
    } catch (e) {
      Logger('ChatInfoScreen').warning('Error loading follows: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsNotifier = ref.watch(groupsProvider.notifier);

    return Scaffold(
      body: FutureBuilder<GroupType>(
        future: groupsNotifier.getGroupTypeById(widget.groupId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final groupType = snapshot.data!;

          return Column(
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 16.h),
                height: MediaQuery.of(context).padding.top,
                color: context.colors.appBarBackground,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      groupType == GroupType.directMessage
                          ? 'Chat Information'
                          : 'Group Information',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.mutedForeground,
                        fontSize: 18.sp,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: context.colors.primary,
                        size: 24.sp,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    groupType == GroupType.directMessage
                        ? DMChatInfo(groupId: widget.groupId)
                        : GroupChatInfo(groupId: widget.groupId),
              ),
            ],
          );
        },
      ),
    );
  }
}
