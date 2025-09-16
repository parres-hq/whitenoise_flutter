import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/user_profile_data_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/chat/chat_management/widgets/create_group_dialog.dart';
import 'package:whitenoise/ui/contact_list/new_group_chat_sheet.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_fade.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

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
  List<Group> _regularGroups = [];

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(groupsProvider.notifier).loadGroups();

      final regularGroups = await ref.read(groupsProvider.notifier).getRegularGroups();
      if (regularGroups.isEmpty) {
        // Show dialog when no groups exist
        if (mounted) {
          _showCreateGroupDialog();
        }
        return;
      }

      final loadTasks = <Future<void>>[];

      for (final group in regularGroups) {
        final existingMembers = ref.read(groupsProvider).groupMembers?[group.mlsGroupId];
        if (existingMembers == null) {
          loadTasks.add(ref.read(groupsProvider.notifier).loadGroupMembers(group.mlsGroupId));
        }
      }

      if (loadTasks.isNotEmpty) {
        await Future.wait(loadTasks);
      }

      setState(() {
        _regularGroups = regularGroups;
      });
    } catch (e) {
      // Handle any errors during group loading
      if (mounted) {
        ref.showErrorToast('Failed to load groups: $e');
      }
    } finally {
      // Always ensure loading state is reset
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  void _showCreateGroupDialog() {
    CreateGroupDialog.show(
      context,
      onCreateGroup: () async {
        try {
          // Close the dialog only
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          // Get contact information for the user to be added
          ContactModel? contactToAdd;
          try {
            // First try to get from follows (cached contacts)
            final followsNotifier = ref.read(followsProvider.notifier);
            final existingFollow = followsNotifier.findFollowByPubkey(widget.contactNpub);

            if (existingFollow != null) {
              contactToAdd = ContactModel.fromMetadata(
                pubkey: existingFollow.pubkey,
                metadata: existingFollow.metadata,
              );
            } else {
              // If not in follows, fetch from user profile data provider
              final userProfileDataNotifier = ref.read(userProfileDataProvider.notifier);
              contactToAdd = await userProfileDataNotifier.getUserProfileData(widget.contactNpub);
            }
          } catch (e) {
            // Create a basic contact model with just the public key
            contactToAdd = ContactModel(
              displayName: 'Unknown User',
              publicKey: widget.contactNpub,
            );
          }

          // Ensure we always have a contact (in case getUserProfileData returns null)
          contactToAdd ??= ContactModel(
            displayName: 'Unknown User',
            publicKey: widget.contactNpub,
          );

          if (!mounted) return;

          await NewGroupChatSheet.show(
            context,
            preSelectedContacts: [contactToAdd],
            onGroupCreated: (group) {
              // Only pop the AddToGroupScreen if group was created successfully
              if (mounted && group != null) {
                Navigator.of(context).pop();
              }
            },
          );
        } catch (e) {
          if (mounted) {
            ref.showErrorToast('Error creating group: $e');
          }
        }
      },
      onCancel: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
    );
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
                  icon: WnImage(
                    AssetsPaths.icChevronLeft,
                    size: 24.w,
                    color: context.colors.primary,
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
                final groupsState = ref.watch(groupsProvider);

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _regularGroups.length,
                  itemBuilder: (context, index) {
                    final group = _regularGroups[index];
                    final members = groupsState.groupMembers?[group.mlsGroupId] ?? [];
                    final memberCount = members.length;

                    final isContactInGroup = members.any(
                      (member) => member.publicKey == widget.contactNpub,
                    );

                    return CheckboxListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      secondary: WnAvatar(
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
          const WnBottomFade(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(
            bottom: 16.h,
          ),
          child: WnFilledButton(
            label: 'Add to Group',
            loading: _isLoading,
            onPressed: _groupsToAddUserTo.isEmpty ? null : _addUserToGroups,
          ),
        ),
      ),
    );
  }
}
