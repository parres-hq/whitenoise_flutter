import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/chat_search_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class ChatSearchWidget extends ConsumerStatefulWidget {
  final String groupId;
  final VoidCallback? onClose;

  const ChatSearchWidget({
    super.key,
    required this.groupId,
    this.onClose,
  });

  @override
  ConsumerState<ChatSearchWidget> createState() => _ChatSearchWidgetState();
}

class _ChatSearchWidgetState extends ConsumerState<ChatSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(chatSearchProvider(widget.groupId));
    final searchNotifier = ref.read(chatSearchProvider(widget.groupId).notifier);

    return Container(
      color: context.colors.solidNeutralBlack, // Black background like in the image
      child: Column(
        children: [
          // Status bar space - so status bar is visible
          SizedBox(height: MediaQuery.of(context).padding.top),

          // Search Bar - White background with minimal spacing
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: context.colors.solidNeutralWhite, // White background
              borderRadius: BorderRadius.circular(0), // Sharp corners
            ),
            child: WnTextFormField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: (value) {
                searchNotifier.updateQuery(value);
                setState(() {}); // Update UI to show/hide clear button
              },
              decoration: InputDecoration(
                hintText: 'chats.searchChat'.tr(),
                hintStyle: TextStyle(
                  color: context.colors.mutedForeground,
                  fontSize: 16.sp,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 12.w),
                  child: WnImage(
                    AssetsPaths.icSearch,
                    width: 20.w,
                    height: 20.w,
                    color: context.colors.mutedForeground,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: WnImage(
                    AssetsPaths.icClose,
                    width: 20.w,
                    height: 20.w,
                    color: context.colors.mutedForeground,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    searchNotifier.updateQuery('');
                    searchNotifier.deactivateSearch();
                    widget.onClose?.call();
                    setState(() {});
                  },
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              style: TextStyle(
                color: context.colors.primary,
                fontSize: 16.sp,
              ),
            ),
          ),

          // Results Counter & Navigation Bar - Black background with white text and more spacing
          if (searchState.query.isNotEmpty &&
              !searchState.isLoading &&
              searchState.matches.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h), // Minimal padding
              color: context.colors.solidNeutralBlack,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous Match Button
                  IconButton(
                    onPressed:
                        searchNotifier.totalMatches > 1 && searchNotifier.currentMatchNumber > 1
                            ? () => searchNotifier.goToPreviousMatch()
                            : null,
                    icon: WnImage(
                      AssetsPaths.icChevronUp,
                      height: 16.w,
                      width: 16.w,
                      color: context.colors.solidPrimary,
                    ),
                    padding: EdgeInsets.all(4.w), // Reduce button padding
                    constraints: BoxConstraints(
                      minWidth: 32.w,
                      minHeight: 32.w,
                    ), // Smaller button size
                  ),

                  // Counter Text - White text on black background
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      'chats.matchesCounter'.tr({
                        'current': searchNotifier.currentMatchNumber,
                        'total': searchNotifier.totalMatches,
                      }),
                      style: TextStyle(
                        color: context.colors.mutedForeground,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  // Next Match Button
                  IconButton(
                    onPressed:
                        searchNotifier.totalMatches > 1 &&
                                searchNotifier.currentMatchNumber < searchNotifier.totalMatches
                            ? () => searchNotifier.goToNextMatch()
                            : null,
                    icon: WnImage(
                      AssetsPaths.icChevronDown,
                      height: 16.w,
                      width: 16.w,
                      color: context.colors.solidPrimary,
                    ),
                    padding: EdgeInsets.all(4.w), // Reduce button padding
                    constraints: BoxConstraints(
                      minWidth: 32.w,
                      minHeight: 32.w,
                    ), // Smaller button size
                  ),
                ],
              ),
            ),

          // No Results Message
          if (searchState.query.isNotEmpty && !searchState.isLoading && searchState.matches.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w), // Minimal padding
              color: context.colors.solidNeutralBlack,
              child: Text(
                'chats.noResultsFound'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.mutedForeground,
                  fontSize: 14.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
