import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class ImageMessage extends StatelessWidget {
  final MessageModel message;

  const ImageMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: CachedNetworkImage(
              imageUrl: message.imageUrl!,
              width: 0.6.sw,
              height: 0.3.sh,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(
                    height: 0.4.sh,
                    color: AppColors.glitch950.withValues(alpha: 0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.glitch50,
                      ),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    height: 0.4.sh,
                    color: AppColors.glitch950.withValues(alpha: 0.1),
                    child: Icon(
                      CarbonIcons.no_image,
                      color: AppColors.glitch50,
                      size: 40.w,
                    ),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
