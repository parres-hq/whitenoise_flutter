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
import 'package:whitenoise/domain/services/image_picker_service.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/ui/settings/profile/widgets/edit_icon.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

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
  final _imagePickerService = ImagePickerService();

  bool _isLoading = false;
  bool _hasChanges = false;
  String? _selectedImagePath;

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
          _descriptionController.text.trim() != group.description ||
          _selectedImagePath != null;

      if (hasChanges != _hasChanges) {
        setState(() {
          _hasChanges = hasChanges;
        });
      }
    }
  }

  Future<void> _pickGroupImage() async {
    try {
      final imagePath = await _imagePickerService.pickProfileImage();
      if (imagePath != null) {
        if (!mounted) return;
        setState(() {
          _selectedImagePath = imagePath;
        });
        _onTextChanged();
      }
    } catch (e) {
      _logger.severe('Error picking group image: $e');
      if (mounted) {
        ref.showErrorToast('chats.failedToPickImage'.tr());
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isLoading) return;

    final activeAccount = ref.read(activePubkeyProvider);
    if (activeAccount == null) {
      ref.showErrorToast('settings.noActiveAccountFound'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newName = _nameController.text.trim();
      final newDescription = _descriptionController.text.trim();
      if (newName.isEmpty) {
        ref.showErrorToast('chats.groupNameCannotBeEmpty'.tr());
        setState(() => _isLoading = false);
        return;
      }
      final newImagePath = _selectedImagePath ?? '';
      if (newImagePath.isNotEmpty) {
        await ref
            .read(groupsProvider.notifier)
            .updateGroupImage(
              groupId: widget.groupId,
              accountPubkey: activeAccount,
              imagePath: newImagePath,
            );
      }

      await ref
          .read(groupsProvider.notifier)
          .updateGroup(
            groupId: widget.groupId,
            accountPubkey: activeAccount,
            name: newName,
            description: newDescription,
          );

      if (mounted) {
        ref.showSuccessToast('chats.groupUpdatedSuccessfully'.tr());
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      _logger.severe('Error updating group: $e');
      ref.showErrorToast('${'chats.failedToUpdateGroup'.tr()}: ${e.toString()}');
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
        appBar: WnAppBar(
          title: Text('ui.editGroup'.tr()),
        ),
        body: Center(
          child: Text('ui.groupNotFound'.tr()),
        ),
      );
    }

    final currentGroupImage = ref.watch(groupsProvider).groupImagePaths?[widget.groupId];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.colors.appBarBackground,
        body: SafeArea(
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
                      'chats.editGroupInformation'.tr(),
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
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              WnAvatar(
                                imageUrl: _selectedImagePath ?? currentGroupImage ?? '',
                                displayName: group.name,
                                size: 96.w,
                                showBorder: true,
                                pubkey: group.nostrGroupId,
                              ),
                              Positioned(
                                right: 5.w,
                                bottom: 4.h,
                                width: 28.w,
                                child: WnEditIconWidget(
                                  onTap: _pickGroupImage,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Gap(36.h),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'chats.groupName'.tr(),
                              style: TextStyle(
                                color: context.colors.primary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Gap(10.h),
                            WnTextFormField(
                              controller: _nameController,
                              hintText: 'chats.enterGroupName'.tr(),
                              readOnly: _isLoading,
                            ),
                            Gap(36.h),
                            Text(
                              'chats.groupDescription'.tr(),
                              style: TextStyle(
                                color: context.colors.primary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Gap(10.h),
                            WnTextFormField(
                              controller: _descriptionController,
                              hintText: 'chats.enterGroupDescription'.tr(),
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
                        label: 'shared.discardChanges'.tr(),
                        visualState: WnButtonVisualState.secondary,
                      ),
                      Gap(8.h),
                      WnFilledButton(
                        onPressed: _hasChanges && !_isLoading ? _saveChanges : null,
                        loading: _isLoading,
                        label: 'shared.save'.tr(),
                      ),
                      Gap(16.h),
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
