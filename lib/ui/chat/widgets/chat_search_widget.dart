import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/chat_search_provider.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

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
      color: Colors.black, // Black background like in the image
      child: Column(
        children: [
          // Status bar space - so status bar is visible
          SizedBox(height: MediaQuery.of(context).padding.top),

          // Search Bar - White background with minimal spacing
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0), // Sharp corners
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: (value) {
                searchNotifier.updateQuery(value);
                setState(() {}); // Update UI to show/hide clear button
              },
              decoration: InputDecoration(
                hintText: 'Search chat',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16.sp,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 20.w,
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[600],
                            size: 20.w,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            searchNotifier.updateQuery('');
                            searchNotifier.deactivateSearch();
                            widget.onClose?.call();
                            setState(() {});
                          },
                        )
                        : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              style: TextStyle(
                color: Colors.black,
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
              color: Colors.black, // Black background like in the image
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous Match Button
                  IconButton(
                    onPressed:
                        searchNotifier.totalMatches > 1 && searchNotifier.currentMatchNumber > 1
                            ? () => searchNotifier.goToPreviousMatch()
                            : null,
                    icon: Icon(
                      Icons.keyboard_arrow_up,
                      color: context.colors.secondary,
                      size: 20.w,
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
                      '${searchNotifier.currentMatchNumber} of ${searchNotifier.totalMatches} matches',
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
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: context.colors.secondary,
                      size: 20.w,
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
              color: Colors.black,
              child: Text(
                'No results found',
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
