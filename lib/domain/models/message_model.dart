// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class MessageModel {
  final String id;
  final String? content;
  final MessageType type;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final User sender;
  final bool isMe;
  final String? audioPath;
  final String? imageUrl;
  final MessageModel? replyTo;
  late final List<Reaction> reactions;
  final String? roomId;
  final MessageStatus status;

  MessageModel({
    required this.id,
    this.content,
    required this.type,
    required this.createdAt,
    this.updatedAt,
    required this.sender,
    required this.isMe,
    this.audioPath,
    this.imageUrl,
    this.replyTo,
    List<Reaction> reactions = const [],
    this.roomId,
    this.status = MessageStatus.sent,
  }) : reactions = List.unmodifiable(reactions);

  MessageModel copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? sender,
    bool? isMe,
    String? audioPath,
    String? imageUrl,
    MessageModel? replyTo,
    List<Reaction>? reactions,
    String? roomId,
    MessageStatus? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sender: sender ?? this.sender,
      isMe: isMe ?? this.isMe,
      audioPath: audioPath ?? this.audioPath,
      imageUrl: imageUrl ?? this.imageUrl,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      roomId: roomId ?? this.roomId,
      status: status ?? this.status,
    );
  }

  String get timeSent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    // Same day - show time (HH:MM)
    if (difference.inDays == 0) {
      final hour = createdAt.hour;
      final minute = createdAt.minute.toString().padLeft(2, '0');

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
      return weekdays[createdAt.weekday - 1];
    }

    // Same year - show month/day
    if (createdAt.year == now.year) {
      final month = createdAt.month.toString().padLeft(2, '0');
      final day = createdAt.day.toString().padLeft(2, '0');
      return '$month/$day';
    }

    // Different year - show full date
    final year = createdAt.year.toString();
    final month = createdAt.month.toString().padLeft(2, '0');
    final day = createdAt.day.toString().padLeft(2, '0');
    return '$month/$day/$year';
  }

  // Alternative version with more detailed recent timestamps
  String get timeSentDetailed {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    // Less than 1 minute
    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    // Less than 1 hour - show minutes
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '${minutes}m ago';
    }

    // Same day but more than 1 hour - show time
    if (difference.inDays == 0) {
      final hour = createdAt.hour;
      final minute = createdAt.minute.toString().padLeft(2, '0');

      // 24-hour format (more compact for chat)
      return '$hour:$minute';
    }

    // Yesterday
    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    // This week - show day name
    if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[createdAt.weekday - 1];
    }

    // Same year - show month/day
    if (createdAt.year == now.year) {
      final month = createdAt.month.toString().padLeft(2, '0');
      final day = createdAt.day.toString().padLeft(2, '0');
      return '$month/$day';
    }

    // Different year - show full date
    final year = createdAt.year.toString();
    final month = createdAt.month.toString().padLeft(2, '0');
    final day = createdAt.day.toString().padLeft(2, '0');
    return '$month/$day/$year';
  }

  // WhatsApp-style formatting (most user-friendly)
  String get timeSentWhatsApp {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    // Today - show time only
    if (difference.inDays == 0) {
      final hour = createdAt.hour;
      final minute = createdAt.minute.toString().padLeft(2, '0');

      // 12-hour format like WhatsApp
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

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return weekdays[createdAt.weekday - 1];
    }

    if (createdAt.year == now.year) {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[createdAt.month - 1]} ${createdAt.day}';
    }

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }
}

class Reaction {
  final String emoji;
  final User user;
  final DateTime createdAt;

  Reaction({required this.emoji, required this.user, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  @override
  bool operator ==(covariant Reaction other) {
    if (identical(this, other)) return true;

    return other.emoji == emoji && other.user == user && other.createdAt == createdAt;
  }

  @override
  int get hashCode => emoji.hashCode ^ user.hashCode ^ createdAt.hashCode;
}

enum MessageType { text, image, audio, video, file }

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  String get imagePath {
    switch (this) {
      case MessageStatus.sending:
      case MessageStatus.failed:
      case MessageStatus.sent:
        return AssetsPaths.icCheckmarkDashed;
      case MessageStatus.delivered:
        return AssetsPaths.icCheckmarkSolid;
      case MessageStatus.read:
        return AssetsPaths.icCheckmarkFilled;
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case MessageStatus.read:
        return context.colors.primary;
      case MessageStatus.delivered:
      case MessageStatus.sent:
      case MessageStatus.sending:
      case MessageStatus.failed:
        return context.colors.mutedForeground;
    }
  }

  Color bubbleStatusColor(BuildContext context) {
    switch (this) {
      case MessageStatus.read:
        return context.colors.input;
      case MessageStatus.delivered:
      case MessageStatus.sent:
      case MessageStatus.sending:
      case MessageStatus.failed:
        return context.colors.input;
    }
  }
}
