import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class ProfileAvatar extends StatelessWidget {
  final String? profileImagePath;
  final String? userFirstLetter;
  final double size;

  const ProfileAvatar({
    super.key,
    this.profileImagePath,
    this.userFirstLetter,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        color: context.colors.solidPrimary,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: _buildChild(context),
      ),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (profileImagePath?.isNotEmpty == true) {
      return Image.network(
        profileImagePath!,
        fit: BoxFit.cover,
        width: size.r,
        height: size.r,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    }

    if (userFirstLetter?.isNotEmpty == true) {
      return Center(
        child: Text(
          userFirstLetter!,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: context.colors.solidNeutralBlack,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(8.r),
      child: Image.asset(
        AssetsPaths.icAvatar,
        fit: BoxFit.contain,
        color: context.colors.solidNeutralBlack,
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    if (userFirstLetter?.isNotEmpty == true) {
      return Center(
        child: Text(
          userFirstLetter!,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: context.colors.solidNeutralBlack,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(8.r),
      child: Image.asset(
        AssetsPaths.icAvatar,
        fit: BoxFit.contain,
        color: context.colors.solidNeutralBlack,
      ),
    );
  }
}
