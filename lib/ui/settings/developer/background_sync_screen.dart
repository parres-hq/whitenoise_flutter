import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/domain/models/background_task_config.dart';
import 'package:whitenoise/domain/services/background_sync_service.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

//TODO: remove this screen later (this is a temporary screen for testing the background sync service)
class BackgroundSyncScreen extends ConsumerStatefulWidget {
  const BackgroundSyncScreen({super.key});

  @override
  ConsumerState<BackgroundSyncScreen> createState() => _BackgroundSyncScreenState();

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BackgroundSyncScreen(),
      ),
    );
  }
}

class _BackgroundSyncScreenState extends ConsumerState<BackgroundSyncScreen> {
  bool _isLoading = false;
  final Map<String, bool> _taskScheduledStatus = {};

  @override
  void initState() {
    super.initState();
    _checkTasksStatus();
  }

  Future<void> _checkTasksStatus() async {
    for (final task in BackgroundSyncService.allTasks) {
      final isScheduled = await BackgroundSyncService.isTaskScheduled(task.uniqueName);
      if (mounted) {
        setState(() {
          _taskScheduledStatus[task.uniqueName] = isScheduled;
        });
      }
    }
  }

  Future<void> _registerTask(BackgroundTaskConfig task) async {
    setState(() => _isLoading = true);
    try {
      if (task.uniqueName == BackgroundSyncService.messagesSyncTask.uniqueName) {
        await BackgroundSyncService.registerMessagesSyncTask();
      } else if (task.uniqueName == BackgroundSyncService.invitesSyncTask.uniqueName) {
        await BackgroundSyncService.registerInvitesSyncTask();
      } else if (task.uniqueName == BackgroundSyncService.metadataRefreshTask.uniqueName) {
        await BackgroundSyncService.registerMetadataSyncTask();
      }
      if (mounted) {
        ref.showSuccessToast('${task.displayName} registered successfully');
        await _checkTasksStatus();
      }
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to register ${task.displayName}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerAllTasks() async {
    setState(() => _isLoading = true);
    try {
      await BackgroundSyncService.registerAllTasks();
      if (mounted) {
        ref.showSuccessToast('All background tasks registered successfully');
        await _checkTasksStatus();
      }
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to register tasks: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelAllTasks() async {
    setState(() => _isLoading = true);
    try {
      await BackgroundSyncService.cancelAllTasks();
      if (mounted) {
        ref.showSuccessToast('All background tasks cancelled successfully');
        await _checkTasksStatus();
      }
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to cancel tasks: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.colors.neutral,
        appBar: WnAppBar(
          automaticallyImplyLeading: false,
          leading: RepaintBoundary(
            child: IconButton(
              onPressed: () => context.pop(),
              icon: WnImage(
                AssetsPaths.icChevronLeft,
                width: 24.w,
                height: 24.w,
                color: context.colors.solidPrimary,
              ),
            ),
          ),
          title: RepaintBoundary(
            child: Text(
              'Background Sync Service',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.solidPrimary,
              ),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: context.colors.neutral,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RepaintBoundary(
                      child: Text(
                        'Available Tasks',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: context.colors.primary,
                        ),
                      ),
                    ),
                    Gap(10.h),
                    ...List.generate(
                      BackgroundSyncService.allTasks.length,
                      (index) {
                        final task = BackgroundSyncService.allTasks[index];
                        final isScheduled = _taskScheduledStatus[task.uniqueName] ?? false;
                        return Column(
                          children: [
                            RepaintBoundary(
                              child: _TaskItem(
                                name: task.displayName,
                                frequency: task.frequencyDisplay,
                                isLoading: _isLoading,
                                isScheduled: isScheduled,
                                onTrigger: () => _registerTask(task),
                              ),
                            ),
                            if (index < BackgroundSyncService.allTasks.length - 1) Gap(8.h),
                          ],
                        );
                      },
                    ),
                    Gap(24.h),
                    RepaintBoundary(
                      child: Text(
                        'Task Management',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: context.colors.primary,
                        ),
                      ),
                    ),
                    Gap(10.h),
                    RepaintBoundary(
                      child: WnFilledButton(
                        label: 'Register All Tasks',
                        onPressed: _isLoading ? null : _registerAllTasks,
                        loading: _isLoading,
                      ),
                    ),
                    Gap(8.h),
                    RepaintBoundary(
                      child: WnFilledButton(
                        label: 'Cancel All Tasks',
                        visualState: WnButtonVisualState.destructive,
                        onPressed: _isLoading ? null : _cancelAllTasks,
                        loading: _isLoading,
                        labelTextStyle: WnButtonSize.large.textStyle().copyWith(
                          color: context.colors.solidNeutralWhite,
                        ),
                      ),
                    ),
                    Gap(MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({
    required this.name,
    required this.frequency,
    required this.isLoading,
    required this.isScheduled,
    required this.onTrigger,
  });

  final String name;
  final String frequency;
  final bool isLoading;
  final bool isScheduled;
  final VoidCallback onTrigger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.colors.avatarSurface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                        Gap(8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color:
                                isScheduled
                                    ? context.colors.success.withValues(alpha: 0.2)
                                    : context.colors.mutedForeground.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            isScheduled
                                ? 'Scheduled'
                                : Platform.isAndroid
                                ? 'Not Scheduled'
                                : 'Unknown state',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  isScheduled
                                      ? context.colors.success
                                      : context.colors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Gap(4.h),
                    Text(
                      'Runs every $frequency',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Gap(12.w),
            ],
          ),
          Gap(8.h),
          WnFilledButton(
            label: 'Schedule Now',
            onPressed: (isLoading || isScheduled) ? null : onTrigger,
            visualState: WnButtonVisualState.secondary,
            size: WnButtonSize.small,
            loading: isLoading,
          ),
        ],
      ),
    );
  }
}
