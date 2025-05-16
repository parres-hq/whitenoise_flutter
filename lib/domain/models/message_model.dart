class MessageModel {
  final int messageType; //0: text message, 1: audio message,
  final String id;
  final String timeSent;
  final List<String> reactions;
  final bool isMe;
  final bool isReplyMessage;
  String? message;
  String? imageUrl;
  String? audioPath;
  String? originalMessage;
  String? originalUser;


  MessageModel({
    required this.messageType,
    required this.id,
    required this.timeSent,
    required this.reactions,
    required this.isMe,
    required this.isReplyMessage,
    this.message,
    this.imageUrl,
    this.audioPath,
    this.originalMessage,
    this.originalUser
  });


}