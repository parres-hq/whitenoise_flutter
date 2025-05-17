import 'package:whitenoise/domain/models/contact_model.dart';

class MessageModel {
  final int messageType; //0: text message, 1: audio message,
  final String id;
  final String timeSent;
  final List<String> reactions;
  final bool isMe;
  final bool isReplyMessage;
  // bool isShowUserAvatar;
  // bool isShowUserName;
  String? message;
  String? imageUrl;
  String? audioPath;
  MessageModel? originalMessage;
  ContactModel? senderData;


  MessageModel({
    required this.messageType,
    required this.id,
    required this.timeSent,
    required this.reactions,
    required this.isMe,
    required this.isReplyMessage,
    // this.isShowUserAvatar=false,
    // this.isShowUserName = false,
    this.message,
    this.imageUrl,
    this.audioPath,
    this.originalMessage,
    this.senderData
  });


}