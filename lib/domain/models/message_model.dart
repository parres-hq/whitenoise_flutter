import 'package:whitenoise/domain/models/user_model.dart';

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

    if (difference.inDays > 365) {
      return '${createdAt.year}/${createdAt.month}/${createdAt.day}';
    } else if (difference.inDays > 7) {
      return '${createdAt.month}/${createdAt.day}';
    } else if (difference.inDays > 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      sender: User.fromJson(json['sender']),
      isMe: json['is_me'] ?? false,
      audioPath: json['audio_path'],
      imageUrl: json['image_url'],
      replyTo: json['reply_to'] != null ? MessageModel.fromJson(json['reply_to']) : null,
      reactions: (json['reactions'] as List<dynamic>?)?.map((e) => Reaction.fromJson(e)).toList() ?? [],
      roomId: json['room_id'],
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status']}',
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sender': sender.toJson(),
      'is_me': isMe,
      'audio_path': audioPath,
      'image_url': imageUrl,
      'reply_to': replyTo?.toJson(),
      'reactions': reactions.map((e) => e.toJson()).toList(),
      'room_id': roomId,
      'status': status.toString().split('.').last,
    };
  }
}

class Reaction {
  final String emoji;
  final User user;
  final DateTime createdAt;

  Reaction({required this.emoji, required this.user, DateTime? createdAt}) : createdAt = createdAt ?? DateTime.now();

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      emoji: json['emoji'],
      user: User.fromJson(json['user']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'emoji': emoji, 'user': user.toJson(), 'created_at': createdAt.toIso8601String()};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reaction && runtimeType == other.runtimeType && emoji == other.emoji && user.id == other.user.id;

  @override
  int get hashCode => emoji.hashCode ^ user.id.hashCode;
}

enum MessageType { text, image, audio, video, file }

enum MessageStatus { sending, sent, delivered, read, failed }
