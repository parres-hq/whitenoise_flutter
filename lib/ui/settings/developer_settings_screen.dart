import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/debug/metadata_debug_screen.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/utils/metadata_cache_utils.dart';

class DeveloperSettingsScreen extends ConsumerStatefulWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  ConsumerState<DeveloperSettingsScreen> createState() => _DeveloperSettingsScreenState();

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeveloperSettingsScreen(),
      ),
    );
  }
}

class _DeveloperSettingsScreenState extends ConsumerState<DeveloperSettingsScreen> {
  bool _isLoading = false;

  Future<void> _clearMetadataCache() async {
    setState(() => _isLoading = true);

    try {
      ref.read(metadataCacheProvider.notifier).clearCache();
      ref.showSuccessToast('Metadata cache cleared successfully');
    } catch (e) {
      ref.showErrorToast('Failed to clear cache: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reloadContacts() async {
    setState(() => _isLoading = true);

    try {
      final activeAccount = await ref.read(activeAccountProvider.notifier).getActiveAccountData();

      if (activeAccount != null) {
        await ref.read(contactsProvider.notifier).loadContacts(activeAccount.pubkey);
        ref.showSuccessToast('Contacts reloaded successfully');
      } else {
        ref.showErrorToast('No active account found');
      }
    } catch (e) {
      ref.showErrorToast('Failed to reload contacts: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cleanExpiredCache() async {
    setState(() => _isLoading = true);

    try {
      ref.read(metadataCacheProvider.notifier).cleanExpiredEntries();
      ref.showSuccessToast('Expired cache entries cleaned');
    } catch (e) {
      ref.showErrorToast('Failed to clean cache: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCacheStats() {
    final stats = MetadataCacheUtils.getCacheHealthReport(ref);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cache Statistics'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Health Score: ${stats['health_score']}%'),
                  Text('Total Entries: ${stats['total_entries']}'),
                  Text('Valid Entries: ${stats['valid_entries']}'),
                  Text('Expired Entries: ${stats['expired_entries']}'),
                  Text('Pending Fetches: ${stats['pending_fetches']}'),
                  Text('Cache Efficiency: ${stats['cache_efficiency']}'),
                  if (stats['has_errors'])
                    Text(
                      'Error: ${stats['error_message']}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 16),
                  const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...((stats['recommendations'] as List<String>).map(
                    (rec) => Text('• $rec'),
                  )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDeveloperOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: (iconColor ?? context.colors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: iconColor ?? context.colors.primary,
            size: 24.w,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14.sp,
            color: context.colors.mutedForeground,
          ),
        ),
        trailing:
            _isLoading
                ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
                : Icon(
                  Icons.arrow_forward_ios,
                  size: 16.w,
                  color: context.colors.mutedForeground,
                ),
        onTap: _isLoading ? null : onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cacheState = ref.watch(metadataCacheProvider);
    final contactsState = ref.watch(contactsProvider);

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
              children: [
                Gap(20.h),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: SvgPicture.asset(
                        AssetsPaths.icChevronLeft,
                        colorFilter: ColorFilter.mode(
                          context.colors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    Text(
                      'Developer Settings',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: context.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Overview
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: context.colors.primary,
                                      size: 20.w,
                                    ),
                                    Gap(8.w),
                                    Text(
                                      'Current Status',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Gap(12.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatusChip(
                                        label: 'Cache',
                                        value: '${cacheState.cache.length}',
                                        color:
                                            cacheState.cache.isNotEmpty
                                                ? Colors.green
                                                : Colors.orange,
                                      ),
                                    ),
                                    Gap(8.w),
                                    Expanded(
                                      child: _StatusChip(
                                        label: 'Contacts',
                                        value: '${contactsState.contactModels?.length ?? 0}',
                                        color:
                                            (contactsState.contactModels?.isNotEmpty ?? false)
                                                ? Colors.green
                                                : Colors.orange,
                                      ),
                                    ),
                                    Gap(8.w),
                                    Expanded(
                                      child: _StatusChip(
                                        label: 'Pending',
                                        value: '${cacheState.pendingFetches.length}',
                                        color:
                                            cacheState.pendingFetches.isEmpty
                                                ? Colors.green
                                                : Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        Gap(24.h),

                        // Cache Management
                        Text(
                          'Cache Management',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primarySolid,
                          ),
                        ),
                        Gap(12.h),

                        _buildDeveloperOption(
                          icon: Icons.clear_all,
                          title: 'Clear Metadata Cache',
                          subtitle: 'Reset all cached user profile data',
                          onTap: _clearMetadataCache,
                          iconColor: Colors.red,
                          isDestructive: true,
                        ),

                        _buildDeveloperOption(
                          icon: Icons.cleaning_services,
                          title: 'Clean Expired Cache',
                          subtitle: 'Remove only expired cache entries',
                          onTap: _cleanExpiredCache,
                          iconColor: Colors.orange,
                        ),

                        _buildDeveloperOption(
                          icon: Icons.bar_chart,
                          title: 'View Cache Statistics',
                          subtitle: 'See detailed cache health and performance',
                          onTap: _showCacheStats,
                          iconColor: Colors.blue,
                        ),

                        Gap(24.h),

                        // Data Operations
                        Text(
                          'Data Operations',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primarySolid,
                          ),
                        ),
                        Gap(12.h),

                        _buildDeveloperOption(
                          icon: Icons.refresh,
                          title: 'Reload Contacts',
                          subtitle: 'Fetch contacts fresh from backend',
                          onTap: _reloadContacts,
                          iconColor: Colors.green,
                        ),

                        Gap(24.h),

                        // Debug Tools
                        Text(
                          'Debug Tools',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primarySolid,
                          ),
                        ),
                        Gap(12.h),

                        _buildDeveloperOption(
                          icon: Icons.bug_report,
                          title: 'Metadata Debug Screen',
                          subtitle: 'Detailed cache inspection and debugging',
                          onTap: () => showMetadataDebugScreen(context),
                          iconColor: Colors.purple,
                        ),

                        _buildDeveloperOption(
                          icon: Icons.analytics,
                          title: 'Log Cache Stats',
                          subtitle: 'Print detailed cache info to console',
                          onTap: () {
                            MetadataCacheUtils.logCacheStats(ref);
                            ref.showInfoToast('Cache stats logged to console');
                          },
                          iconColor: Colors.indigo,
                        ),

                        Gap(32.h),

                        // Warning
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.amber[800],
                                size: 20.w,
                              ),
                              Gap(8.w),
                              Expanded(
                                child: Text(
                                  'Developer tools - use with caution. Some operations may affect app performance.',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.amber[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Gap(MediaQuery.of(context).padding.bottom),
                      ],
                    ),
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

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Gap(2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: context.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
