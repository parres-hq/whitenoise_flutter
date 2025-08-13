import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_fade.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_chip.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class ChooseNewAdminDialog extends ConsumerStatefulWidget {
  const ChooseNewAdminDialog({super.key, required this.groupId, required this.currentMemberNpub});
  final String groupId;
  final String currentMemberNpub;
  static Future<List<String>?> show(
    BuildContext context, {
    required String groupId,
    required String memberNpub,
  }) async {
    return WnBottomSheet.show<List<String>?>(
      context: context,
      showCloseButton: false,
      builder:
          (context) => ChooseNewAdminDialog(
            groupId: groupId,
            currentMemberNpub: memberNpub,
          ),
    );
  }

  @override
  ConsumerState<ChooseNewAdminDialog> createState() => _ChooseNewAdminDialogState();
}

class _ChooseNewAdminDialogState extends ConsumerState<ChooseNewAdminDialog> {
  final List<User> _selectedUsers = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _addToList(User user) {
    setState(() {
      _selectedUsers.add(user);
    });
  }

  void _removeFromList(User user) {
    setState(() {
      _selectedUsers.remove(user);
    });
  }

  void _toggleSelection(User user) {
    if (_selectedUsers.contains(user)) {
      _removeFromList(user);
    } else {
      _addToList(user);
    }
  }

  void _confirmSelection() {
    if (_selectedUsers.isEmpty) return;
    Navigator.pop(context, _selectedUsers.map((e) => e.publicKey).toList());
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allMembers =
        ref
            .watch(groupsProvider)
            .groupMembers?[widget.groupId]
            ?.where((member) => member.publicKey != widget.currentMemberNpub)
            .toList() ??
        [];

    final members =
        _searchQuery.isEmpty
            ? allMembers
            : allMembers
                .where(
                  (member) =>
                      member.displayName.toLowerCase().contains(_searchQuery) ||
                      member.publicKey.toLowerCase().contains(_searchQuery),
                )
                .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Icon(
                CarbonIcons.chevron_left,
                size: 24,
                color: context.colors.primary,
              ),
            ),
            Gap(16.w),
            Text(
              'Choose New Admins',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Gap(32.h),
        WnTextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: Icon(
              CarbonIcons.search,
              color: context.colors.mutedForeground,
            ),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: Icon(CarbonIcons.close, color: context.colors.mutedForeground),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                    : null,
          ),
        ),
        Gap(16.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children:
              _selectedUsers.map(
                (member) {
                  final displayName = member.displayName.split(' ').first;
                  return WnChip(
                    label: displayName,
                    avatarUrl: member.imagePath,
                    onRemove: () => _removeFromList(member),
                  ).animate().fadeIn();
                },
              ).toList(),
        ),
        Gap(8.h),
        Expanded(
          child: ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isSelected = _selectedUsers.contains(member);
              return CheckboxListTile(
                secondary: ContactAvatar(
                  imageUrl: member.imagePath ?? '',
                  displayName: member.displayName,
                  size: 56.r,
                ),
                title: Text(
                  member.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: context.colors.primary,
                  ),
                ),
                subtitle: Text(
                  member.publicKey.formatPublicKey(),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,

                    fontSize: 12.sp,
                    color: context.colors.mutedForeground,
                  ),
                ),
                value: isSelected,
                onChanged: (value) {
                  if (value == true) {
                    _toggleSelection(member);
                  } else {
                    _removeFromList(member);
                  }
                },
              );
            },
          ),
        ),
        const WnBottomFade(),
        WnFilledButton(
          title: 'Leave Group',
          visualState: WnButtonVisualState.destructive,
          onPressed: _selectedUsers.isEmpty ? null : _confirmSelection,
        ),
        Gap(16.h),
      ],
    );
  }
}
