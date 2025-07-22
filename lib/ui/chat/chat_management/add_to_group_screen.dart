import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/bottom_fade.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';

class AddToGroupScreen extends ConsumerStatefulWidget {
  const AddToGroupScreen({super.key, required this.contactNpub});
  final String contactNpub;

  @override
  ConsumerState<AddToGroupScreen> createState() => _AddToGroupScreenState();
}

class _AddToGroupScreenState extends ConsumerState<AddToGroupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroups();
    });
  }

  // should store id of groups to add user to
  final List<String> _groupsToAddUserTo = [];
  bool _isLoading = false;

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });
    await ref.read(groupsProvider.notifier).loadGroups();

    final groups = ref.read(groupsProvider).groups;
    if (groups == null || groups.isEmpty) {
      return;
    }

    final loadTasks = <Future<void>>[];

    for (final group in groups) {
      final existingMembers = ref.read(groupsProvider).groupMembers?[group.mlsGroupId];
      if (existingMembers == null) {
        loadTasks.add(ref.read(groupsProvider.notifier).loadGroupMembers(group.mlsGroupId));
      }
    }

    if (loadTasks.isNotEmpty) {
      await Future.wait(loadTasks);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addUserToGroups() async {
    if (_groupsToAddUserTo.isEmpty) {
      ref.showErrorToast('No groups selected');
      return;
    }

    int successCount = 0;
    final int totalGroups = _groupsToAddUserTo.length;
    setState(() {
      _isLoading = true;
    });

    for (final groupId in _groupsToAddUserTo) {
      try {
        await ref
            .read(groupsProvider.notifier)
            .addToGroup(
              groupId: groupId,
              membersNpubs: [widget.contactNpub],
            );
        successCount++;
      } catch (e) {
        final group = ref.read(groupsProvider).groupsMap?[groupId];
        final groupName = group?.name ?? 'Unknown Group';
        ref.showErrorToast('Failed to add user to $groupName: $e');
      }
    }

    if (successCount > 0) {
      ref.showSuccessToast(
        'Successfully added user to $successCount of $totalGroups group${totalGroups > 1 ? 's' : ''}',
      );

      if (successCount == totalGroups) {
        // All successful, go back
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              spacing: 8.w,
              children: [
                IconButton(
                  icon: Icon(
                    CarbonIcons.chevron_left,
                    color: context.colors.primary,
                    size: 24.sp,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  'Add to Group',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.mutedForeground,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ),
          Gap(32.h),
          Flexible(
            child: Consumer(
              builder: (context, ref, child) {
                final allGroups = ref.watch(groupsProvider).groups ?? [];
                final groupsState = ref.watch(groupsProvider);

                final regularGroups =
                    allGroups.where((group) => group.groupType == GroupType.group).toList();

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: regularGroups.length,
                  itemBuilder: (context, index) {
                    final group = regularGroups[index];
                    final members = groupsState.groupMembers?[group.mlsGroupId] ?? [];
                    final memberCount = members.length;

                    final isContactInGroup = members.any(
                      (member) => member.publicKey == widget.contactNpub,
                    );

                    return CheckboxListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      secondary: ContactAvatar(
                        imageUrl: '',
                        displayName: group.name,
                        size: 56.w,
                      ),
                      title: Text(
                        group.name,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                      subtitle: Text(
                        '($memberCount members)',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.mutedForeground,
                          fontWeight: FontWeight.w500,

                          fontSize: 12.sp,
                        ),
                      ),

                      enabled: !isContactInGroup,
                      value: _groupsToAddUserTo.contains(group.mlsGroupId) || isContactInGroup,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _groupsToAddUserTo.add(group.mlsGroupId);
                          } else {
                            _groupsToAddUserTo.remove(group.mlsGroupId);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          const BottomFade(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(
            bottom: 16.h,
          ),
          child: AppFilledButton(
            title: 'Add to Group',
            loading: _isLoading,
            onPressed: _groupsToAddUserTo.isEmpty ? null : _addUserToGroups,
          ),
        ),
      ),
    );
  }
}
