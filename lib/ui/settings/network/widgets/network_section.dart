import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class NetworkSection extends StatelessWidget {
  const NetworkSection({
    super.key,
    required this.title,
    required this.items,
    required this.emptyText,
    required this.onAddPressed,
    required this.onInfoPressed,
    this.isLoading = false,
    this.error,
    this.onRefresh,
  });

  final String title;
  final List<RelayInfo> items;
  final String emptyText;
  final VoidCallback onAddPressed;
  final VoidCallback onInfoPressed;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 24.sp, color: AppColors.glitch900),
              ),
              Row(
                children: [
                  if (onRefresh != null) ...[
                    GestureDetector(
                      onTap: isLoading ? null : onRefresh,
                      child: Icon(
                        Icons.refresh,
                        size: 18.w,
                        color:
                            isLoading
                                ? AppColors.glitch400
                                : AppColors.glitch600,
                      ),
                    ),
                    Gap(16.w),
                  ],
                  GestureDetector(
                    onTap: onInfoPressed,
                    child: SvgPicture.asset(
                      AssetsPaths.icHelp,
                      width: 14.w,
                      height: 14.w,
                    ),
                  ),
                  Gap(16.w),
                  GestureDetector(
                    onTap: onAddPressed,
                    child: SvgPicture.asset(
                      AssetsPaths.icAdd,
                      height: 14.w,
                      width: 14.w,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade600,
                    size: 16.w,
                  ),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      error!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (isLoading)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.glitch600,
                ),
              ),
            ),
          )
        else if (items.isEmpty && error == null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            child: Text(
              emptyText,
              style: TextStyle(fontSize: 17.sp, color: AppColors.glitch600),
            ),
          )
        else if (!isLoading)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return RelayItem(relay: items[index]);
            },
          ),
        Gap(40.w),
      ],
    );
  }
}

class RelayItem extends StatelessWidget {
  const RelayItem({super.key, required this.relay});

  final RelayInfo relay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            relay.url,
            style: TextStyle(fontSize: 18.sp, color: AppColors.glitch900),
          ),
          Row(
            children: [
              SvgPicture.asset(
                relay.connected
                    ? AssetsPaths.icConnected
                    : AssetsPaths.icDisconnected,
                width: 8.w,
                height: 8.w,
              ),
              Gap(8.w),
              Text(
                relay.connected ? 'Connected' : 'Disconnected',
                style: TextStyle(fontSize: 12.sp, color: AppColors.glitch600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RelayInfo {
  final String url;
  final bool connected;

  const RelayInfo({required this.url, required this.connected});
}
