import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';

/// Extension for handling chat navigation after group/chat creation
/// This provides a consistent pattern for navigating to a chat and popping back to home
extension ChatNavigationExtension on BuildContext {
  /// Navigates to a chat immediately after creation and pops back to home
  /// This creates the feeling of opening the chat immediately while ensuring
  /// the user can navigate back to home easily
  void navigateToGroupChatAndPopToHome(GroupData groupData) {
    // First navigate to home to clear the navigation stack
    go(Routes.home);

    // Then immediately navigate to the specific group chat
    Routes.goToChat(this, groupData.mlsGroupId);
  }

  /// Creates a callback function that can be used with onChatCreated callbacks
  /// This is useful for passing to bottom sheets and other components
  ValueChanged<GroupData?> createChatNavigationCallback() {
    return (GroupData? groupData) {
      if (groupData != null) {
        navigateToGroupChatAndPopToHome(groupData);
      }
    };
  }
}
