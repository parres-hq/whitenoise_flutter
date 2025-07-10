import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
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
      _loadContacts();
    });
  }

  Future<void> _loadContacts() async {
    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData != null) {
        await ref.read(contactsProvider.notifier).loadContacts(activeAccountData.pubkey);
      }
    } catch (e) {
      Logger('ChatInfoScreen').warning('Error loading contacts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupDetails = ref.watch(groupsProvider).groupsMap?[widget.groupId];

    return Scaffold(
      body: Column(
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
                  'Chat Information',
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
                groupDetails?.groupType == GroupType.directMessage
                    ? DMChatInfo(groupId: widget.groupId)
                    : GroupChatInfo(groupId: widget.groupId),
          ),
        ],
      ),
    );
  }
}
