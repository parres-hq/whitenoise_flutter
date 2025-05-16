class Message {
  int messageType; //0: text message, 1: audio message,
  String id;
  String timeSent;
  List<String> reactions;
  bool isMe;
  String? message;
  String? imageUrl;
  String? audioPath;
  bool isReplyMessage;
  String? originalMessage;
  String? originalUser;


  Message({
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