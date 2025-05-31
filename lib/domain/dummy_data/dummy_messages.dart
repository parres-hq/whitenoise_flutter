import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';

final User marekContact = User(
  id: '1',
  name: "Marek Kowalski",
  email: "marek.kowalski@email.com",
  publicKey: "pk_marek_123456789",
  imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
);

final User maxContact = User(
  id: '2',
  name: "Max Hillebrand",
  email: "max.hillebrand@email.com",
  publicKey: "pk_max_987654321",
  imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png",
);

final User currentUser = User(
  id: 'current_user_id',
  name: "Alex Johnson",
  email: "alex.johnson@email.com",
  publicKey: "pk_alex_456123789",
  imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_2_11_15_39.png",
);

// Original messages for replies
final MessageModel _originalMessage1 = MessageModel(
  id: '100',
  content: 'I am also doing well',
  type: MessageType.text,
  createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
  sender: marekContact,
  isMe: false,
  status: MessageStatus.read,
);

final MessageModel _originalMessage2 = MessageModel(
  id: '101',
  content: 'Good to hear that',
  type: MessageType.text,
  createdAt: DateTime.now().subtract(const Duration(minutes: 26)),
  sender: maxContact,
  isMe: false,
  status: MessageStatus.read,
);

// Chat conversation
final List<MessageModel> messages = [
  // Recent messages
  MessageModel(
    id: '17',
    content: 'This message has been delivered',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    sender: currentUser,
    isMe: true,
    status: MessageStatus.delivered,
    reactions: [],
  ),
  MessageModel(
    id: '18',
    content: 'This message failed to send',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    sender: currentUser,
    isMe: true,
    status: MessageStatus.failed,
    reactions: [],
  ),
  MessageModel(
    id: '19',
    content: 'This message is being sent',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    sender: currentUser,
    isMe: true,
    status: MessageStatus.sending,
    reactions: [],
  ),
  MessageModel(
    id: '11',
    content: 'This message has been read',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    sender: currentUser,
    isMe: true,
    status: MessageStatus.read,
    reactions: [],
  ),

  // Message with multiple reactions
  MessageModel(
    id: '12',
    content: 'Testing reaction overflow',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 16)),
    sender: marekContact,
    isMe: false,
    status: MessageStatus.read,
    reactions: [
      Reaction(emoji: '👍', user: currentUser),
      Reaction(emoji: '❤️', user: maxContact),
      Reaction(emoji: '👍', user: currentUser),
      Reaction(emoji: '😀', user: marekContact),
      Reaction(emoji: '🙏', user: marekContact),
      Reaction(emoji: '🔥', user: marekContact),
    ],
  ),

  // Conversation flow
  MessageModel(
    id: '10',
    content: 'Goodbye',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 11)),
    sender: currentUser,
    isMe: true,
    status: MessageStatus.read,
    reactions: [Reaction(emoji: '👍', user: marekContact)],
  ),
  MessageModel(
    id: '9',
    content: 'Bye',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    sender: marekContact,
    isMe: false,
    status: MessageStatus.read,
    reactions: [
        Reaction(emoji: '👍', user: currentUser), Reaction(emoji: '💗', user: currentUser)],
  ),

  // Audio messages
  MessageModel(
    id: '8',
    type: MessageType.audio,
    createdAt: DateTime.now().subtract(const Duration(minutes: 13)),
    sender: currentUser,
    isMe: true,
    audioPath: "https://commondatastorage.googleapis.com/codeskulptor-assets/Collision8-Bit.ogg",
    status: MessageStatus.read,
    reactions: [],
  ),
  // Messages with replies
  MessageModel(
    id: '6',
    content: 'I am also doing well',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    sender: currentUser,
    isMe: true,
    replyTo: _originalMessage2,
    status: MessageStatus.read,
    reactions: [],
  ),
  MessageModel(
    id: '5',
    content: 'What about you?',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 16)),
    sender: marekContact,
    isMe: false,
    replyTo: _originalMessage1,
    status: MessageStatus.read,
    reactions: [],
  ),

  // Image message
  MessageModel(
    id: '5',
    content: 'Check this image',
    type: MessageType.image,
    createdAt: DateTime.now().subtract(const Duration(minutes: 16)),
    sender: marekContact,
    isMe: false,
    imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
    status: MessageStatus.read,
    reactions: [],
  ),

  // Initial conversation
  MessageModel(
    id: '3',
    content: 'I am fine, thank you',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 17)),
    sender: currentUser,
    isMe: true,
    status: MessageStatus.read,
  ),
  MessageModel(
    id: '2',
    content: 'How are you?',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
    sender: marekContact,
    isMe: false,
    status: MessageStatus.read,
  ),
  MessageModel(
    id: '2',
    content: 'Hi there',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 19)),
    sender: currentUser,
    isMe: true,
    status: MessageStatus.read,
    reactions: [],
  ),
  MessageModel(
    id: '0',
    content: 'Hello',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    sender: marekContact,
    isMe: false,
    status: MessageStatus.read,
    reactions: [],
  ),
];
