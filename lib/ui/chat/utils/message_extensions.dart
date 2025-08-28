import 'package:flutter/material.dart';
import 'package:whitenoise/src/rust/api/messages.dart';

extension MessageWithTokensExtensions on MessageWithTokens {
  /// Convert BigInt timestamp to DateTime
  DateTime get createdAtDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt.toInt());

  /// Get formatted time sent (similar to MessageModel.timeSent)
  String get timeSent {
    final now = DateTime.now();
    final messageTime = createdAtDateTime;
    final difference = now.difference(messageTime);

    // Same day - show time (HH:MM)
    if (difference.inDays == 0) {
      final hour = messageTime.hour;
      final minute = messageTime.minute.toString().padLeft(2, '0');

      // 12-hour format with AM/PM
      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    }

    // Yesterday
    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    // This week (2-6 days ago) - show day name
    if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[messageTime.weekday - 1];
    }

    // Same year - show month/day
    if (messageTime.year == now.year) {
      final month = messageTime.month.toString().padLeft(2, '0');
      final day = messageTime.day.toString().padLeft(2, '0');
      return '$month/$day';
    }

    // Different year - show full date
    final year = messageTime.year.toString();
    final month = messageTime.month.toString().padLeft(2, '0');
    final day = messageTime.day.toString().padLeft(2, '0');
    return '$month/$day/$year';
  }

  /// Check if message is from the current user
  /// Note: This requires the current user's pubkey to be passed in
  bool isFromUser(String currentUserPubkey) {
    return pubkey == currentUserPubkey;
  }

  /// Get display content (fallback to empty string if null)
  String get displayContent => content ?? '';

  /// Check if message has content
  bool get hasContent => content != null && content!.isNotEmpty;

  /// Get sender name (extract from pubkey or use a default)
  String get senderName {
    // For now, just use the first 8 characters of pubkey as name
    // In a real app, you'd probably have a user lookup service
    if (pubkey.length >= 8) {
      return pubkey.substring(0, 8);
    }
    return pubkey;
  }
}

/// Helper class to manage current user context for messages
class MessageHelper {
  static String? _currentUserPubkey;

  static void setCurrentUserPubkey(String pubkey) {
    _currentUserPubkey = pubkey;
  }

  static String? getCurrentUserPubkey() {
    return _currentUserPubkey;
  }

  static bool isMessageFromCurrentUser(MessageWithTokens message) {
    final currentPubkey = _currentUserPubkey;
    if (currentPubkey == null) return false;
    return message.isFromUser(currentPubkey);
  }
}

/// Mock message status enum since MessageWithTokens doesn't have status
enum MockMessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  String get imagePath {
    // Return placeholder paths - you'd need to update with actual asset paths
    switch (this) {
      case MockMessageStatus.sending:
      case MockMessageStatus.failed:
      case MockMessageStatus.sent:
        return 'assets/icons/checkmark_dashed.png';
      case MockMessageStatus.delivered:
        return 'assets/icons/checkmark_solid.png';
      case MockMessageStatus.read:
        return 'assets/icons/checkmark_filled.png';
    }
  }

  Color bubbleStatusColor(BuildContext context) {
    // Return placeholder colors - you'd need to update with actual theme colors
    switch (this) {
      case MockMessageStatus.read:
        return Colors.blue;
      case MockMessageStatus.delivered:
      case MockMessageStatus.sent:
      case MockMessageStatus.sending:
      case MockMessageStatus.failed:
        return Colors.grey;
    }
  }
}
