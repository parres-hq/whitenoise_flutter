import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_text_field.dart';

class EditGroupScreen extends ConsumerStatefulWidget {
  final String groupId;

  const EditGroupScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends ConsumerState<EditGroupScreen> {
  final _logger = Logger('EditGroupScreen');
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
    _nameController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _descriptionController.removeListener(_onTextChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadGroupData() {
    final group = ref.read(groupsProvider).groupsMap?[widget.groupId];
    if (group != null) {
      _nameController.text = group.name;
      _descriptionController.text = group.description;
    }
  }

  void _onTextChanged() {
    final group = ref.read(groupsProvider).groupsMap?[widget.groupId];
    if (group != null) {
      final hasChanges =
          _nameController.text.trim() != group.name ||
          _descriptionController.text.trim() != group.description;

      if (hasChanges != _hasChanges) {
        setState(() {
          _hasChanges = hasChanges;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isLoading) return;

    final activeAccount = ref.read(activePubkeyProvider);
    if (activeAccount == null) {
      _showErrorSnackBar('No active account found');
      return;
    }

    final group = ref.read(groupsProvider).groupsMap?[widget.groupId];
    if (group == null) {
      _showErrorSnackBar('Group not found');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newName = _nameController.text.trim();
      final newDescription = _descriptionController.text.trim();

      await group.updateGroupData(
        accountPubkey: activeAccount,
        groupData: FlutterGroupDataUpdate(
          name: newName != group.name ? newName : null,
          description: newDescription != group.description ? newDescription : null,
        ),
      );

      // Refresh group data
      await ref.read(groupsProvider.notifier).loadGroupDetails(widget.groupId);

      if (mounted) {
        _showSuccessSnackBar('Group updated successfully');
        context.pop();
      }
    } catch (e) {
      _logger.severe('Error updating group: $e');
      _showErrorSnackBar('Failed to update group: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: context.colors.destructive,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: context.colors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupsProvider).groupsMap?[widget.groupId];

    if (group == null) {
      return Scaffold(
        backgroundColor: context.colors.neutral,
        appBar: const WnAppBar(
          title: Text('Edit Group'),
        ),
        body: const Center(
          child: Text('Group not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.neutral,
      appBar: WnAppBar(
        title: const Text('Edit Group'),
        actions: [
          TextButton(
            onPressed: _hasChanges && !_isLoading ? _saveChanges : null,
            child:
                _isLoading
                    ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.primary,
                      ),
                    )
                    : Text(
                      'Save',
                      style: TextStyle(
                        color:
                            _hasChanges ? context.colors.primary : context.colors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Avatar
            Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: Implement image picker
                  _showErrorSnackBar('Image upload not implemented yet');
                },
                child: Stack(
                  children: [
                    WnAvatar(
                      imageUrl: '',
                      displayName: group.name,
                      size: 96.w,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.neutral,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 16.w,
                          color: context.colors.primaryForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Gap(32.h),

            // Group Name
            Text(
              'Group Name',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.primary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(8.h),
            WnTextField(
              textController: _nameController,
              hintText: 'Enter group name',
              readOnly: !_isLoading,
            ),
            Gap(24.h),

            // Group Description
            Text(
              'Group Description',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.primary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(8.h),
            WnTextField(
              textController: _descriptionController,
              hintText: 'Enter group description',
              // maxLines: 3,
              readOnly: !_isLoading,
            ),
            Gap(32.h),

            // Save Button
            WnFilledButton(
              onPressed: _hasChanges && !_isLoading ? _saveChanges : null,
              loading: _isLoading,
              label: 'Save Changes',
            ),
          ],
        ),
      ),
    );
  }
}
