import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/models/relay_status.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/settings/network/relay_options_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/network/widgets/network_section.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class RelayTile extends StatelessWidget {
  const RelayTile({
    super.key,
    required this.relayInfo,
    this.showOptions = false,
  });

  final RelayInfo relayInfo;
  final bool showOptions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
      ),
      child: ListTile(
        onTap:
            showOptions
                ? () {
                  RelayOptionsBottomSheet.show(
                    context: context,
                    relayInfo: relayInfo,
                  );
                }
                : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 4.h,
        ),
        leading: Icon(
          relayInfo.status.getIcon(),
          color: relayInfo.status.getColor(context),
        ),
        title: Text(
          relayInfo.url.sanitizedUrl,
          style: TextStyle(
            color: context.colors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
          ),
        ),
        trailing:
            showOptions
                ? Icon(
                  CarbonIcons.overflow_menu_horizontal,
                  color: context.colors.primary,
                  size: 23.sp,
                )
                : null,
      ),
    );
  }
}
