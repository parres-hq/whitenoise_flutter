class ChatModel {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool hasAttachment;
  final String imagePath;

  ChatModel({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.hasAttachment = false,
    this.imagePath = '',
  });
}