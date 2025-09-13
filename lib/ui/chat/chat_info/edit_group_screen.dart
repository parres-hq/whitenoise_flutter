import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/ui/settings/profile/widgets/edit_icon.dart';

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
      ref.showErrorToast('No active account found');
      return;
    }

    final group = ref.read(groupsProvider).groupsMap?[widget.groupId];
    if (group == null) {
      ref.showErrorToast('Group not found');
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
        ref.showSuccessToast('Group updated successfully');
        // Small delay to allow toast to show before navigation
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      _logger.severe('Error updating group: $e');
      ref.showErrorToast('Failed to update group: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.colors.appBarBackground,
        body: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: context.colors.neutral,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Gap(21.h),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: WnImage(
                        AssetsPaths.icChevronLeft,
                        width: 20.w,
                        height: 20.w,
                        color: context.colors.primary,
                      ),
                    ),
                    Text(
                      'Edit Group Information',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.mutedForeground,
                        fontSize: 18.sp,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        Gap(65.h),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Implement image picker
                            },
                            child: Stack(
                              children: [
                                WnAvatar(
                                  imageUrl: '',
                                  displayName: group.name,
                                  size: 96.w,
                                  showBorder: true,
                                ),
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: EditIconWidget(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Gap(36.h),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Group Name:',
                              style: TextStyle(
                                color: context.colors.primary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Gap(10.h),
                            WnTextFormField(
                              controller: _nameController,
                              hintText: 'Enter group name',
                              readOnly: _isLoading,
                            ),
                            Gap(36.h),
                            Text(
                              'Group Description:',
                              style: TextStyle(
                                color: context.colors.primary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Gap(10.h),
                            WnTextFormField(
                              controller: _descriptionController,
                              hintText: 'Enter group description',
                              maxLines: 3,
                              minLines: 3,
                              keyboardType: TextInputType.multiline,
                              readOnly: _isLoading,
                            ),
                            Gap(32.h),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WnFilledButton(
                        onPressed: _hasChanges && !_isLoading ? () => context.pop() : null,
                        label: 'Discard Changes',
                        visualState: WnButtonVisualState.secondary,
                      ),
                      Gap(4.h),
                      WnFilledButton(
                        onPressed: _hasChanges && !_isLoading ? _saveChanges : null,
                        loading: _isLoading,
                        label: 'Save',
                      ),
                      Gap(36.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
