import 'package:flutter/material.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.actions = const [],
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.title,
    this.leading,
  }) : pinned = false,
       floating = false,
       snap = false,
       stretch = false,
       isTransparent = false,
       expandedHeight = null,
       _isSliver = false;

  const CustomAppBar.sliver({
    super.key,
    this.actions = const [],
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.title,
    this.leading,
    this.pinned = false,
    this.floating = false,
    this.snap = false,
    this.stretch = false,
    this.isTransparent = false,
    this.expandedHeight,
  }) : _isSliver = true;

  final Widget? leading;
  final Widget? title;
  final List<Widget> actions;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final bool pinned;
  final bool floating;
  final bool snap;
  final bool stretch;
  final double? expandedHeight;
  final bool _isSliver;
  final bool isTransparent;

  @override
  Widget build(BuildContext context) {
    if (_isSliver) {
      return SliverAppBar(
        centerTitle: centerTitle,
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: leading,
        title: title,
        actions: actions,
        titleSpacing: 2.w,
        elevation: 0,
        pinned: pinned,
        floating: floating,
        snap: snap,
        stretch: stretch,
        expandedHeight: expandedHeight,
        toolbarHeight: 64.h,
      );
    }

    return AppBar(
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: title,
      actions: actions,
      titleSpacing: 2.w,
      elevation: 0,
      backgroundColor:
          isTransparent ? Colors.transparent : context.theme.appBarTheme.backgroundColor,
      iconTheme:
          isTransparent
              ? context.theme.iconTheme.copyWith(
                color: context.colors.primary,
              )
              : context.theme.iconTheme.copyWith(
                color: context.colors.solidPrimary,
              ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(64.h);
}
