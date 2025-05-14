
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/core/utils/assets_paths.dart';
import 'package:whitenoise/features/contact_list/presentation/search_screen.dart';

class ContactListAppBar extends StatelessWidget {
  const ContactListAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          AssetsPaths.icImage,
          width: 32.w,
          height: 32.w,
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            SearchBottomSheet.show(context);
          },
          child: SvgPicture.asset(
            AssetsPaths.icSearch,
          ),
        ),
        Gap(24.w),
        SvgPicture.asset(
          AssetsPaths.icAdd,
        ),
      ],
    );
  }
}
