import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/providers/relay_provider.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/settings/network/widgets/relay_tile.dart';

class RelayExpansionTile extends StatefulWidget {
  final String title;
  final RelayState relayState;
  final VoidCallback? onInfoTap;
  final VoidCallback? onAddTap;
  final GlobalKey helpIconKey;
  const RelayExpansionTile({
    super.key,
    required this.title,
    required this.relayState,
    this.onInfoTap,
    this.onAddTap,
    required this.helpIconKey,
  });

  @override
  State<RelayExpansionTile> createState() => _RelayExpansionTileState();
}

class _RelayExpansionTileState extends State<RelayExpansionTile> {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      showTrailingIcon: false,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Row(
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: context.colors.mutedForeground,
              fontWeight: FontWeight.w600,
              fontSize: 16.w,
            ),
          ),
          Gap(8.w),
          if (widget.onInfoTap != null)
            InkWell(
              key: widget.helpIconKey,
              onTap: widget.onInfoTap,
              child: Icon(
                CarbonIcons.help,
                color: context.colors.mutedForeground,
                size: 18.sp,
              ),
            ),
          const Spacer(),
          if (widget.onAddTap != null)
            InkWell(
              onTap: widget.onAddTap,
              child: Icon(
                CarbonIcons.add,
                color: context.colors.primary,
                size: 23.sp,
              ),
            ),
        ],
      ),

      children: [
        if (widget.relayState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (widget.relayState.error != null)
          Center(child: Text('Error: ${widget.relayState.error}'))
        else
          Column(
            children:
                widget.relayState.relays
                    .map(
                      (relay) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: RelayTile(
                          relayInfo: relay,
                          showOptions: true,
                        ),
                      ),
                    )
                    .toList(),
          ),
      ],
    );
  }
}
