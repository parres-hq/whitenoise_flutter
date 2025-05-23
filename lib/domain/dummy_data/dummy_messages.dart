import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';

// Sample contacts
final User marekContact = User(
  id: '1',
  name: "Marek",
  email: "marek@email.com",
  publicKey: "asdfasdfasdfa",
  imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
);

final User maxContact = User(
  id: '2',
  name: "Max Hillebrand",
  email: "max@email.com",
  publicKey: "qwerqwerqwer",
  imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png",
);

final User meContact = User(
  id: '3',
  name: "Me",
  email: "me@email.com",
  publicKey: "zxcvzxcvzxcv",
  imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_2_11_15_39.png",
);

// Original messages for replies
final MessageModel originalMessage1 = MessageModel(
  id: '100',
  content: 'I am also fine',
  type: MessageType.text,
  createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
  sender: marekContact,
  isMe: false,
  imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png",
  status: MessageStatus.read,
);

MessageModel originalMessage2=MessageModel(
    id: '101',
    message: 'Good to hear that',
    timeSent: '10:05 AM',
    reactions: ['👍'],
    isMe: false,
    messageType: 0,
    isReplyMessage: false,
    senderData: ContactModel(name: "Marek", email: "marek@email.com", publicKey: "asdfasdfasdfa", imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"),
    imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png"
);

// Individual chat messages
List<MessageModel> messages = [
  MessageModel(
      id: '12',
      message: '',
      timeSent: '10:04 AM',
      reactions: ['👍'],
      isMe: false,
      messageType: 0,
      isReplyMessage: false,
      imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"
  ),
  MessageModel(
      id: '11',
      message: '',
      timeSent: '10:05 AM',
      reactions: ['👍', '❤️', '😂'],
      isMe: true,
      messageType: 0,
      isReplyMessage: false,
      imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png"
  ),
  MessageModel(
    id: '10',
    message: 'Goodbye',
    timeSent: '10:09 AM',
    reactions: [
      '👍',
    ],
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
      Reaction(emoji: '👍', user: meContact),
      Reaction(emoji: '💗', user: meContact),
      Reaction(emoji: '😂', user: meContact),
    ],
  ),
  MessageModel(
      id: '8',
      message: 'Yes',
      timeSent: '10:07 AM',
      reactions: ['❤️'],
      isMe: true,
      messageType: 1,
      isReplyMessage: false,
      audioPath: "https://commondatastorage.googleapis.com/codeskulptor-assets/Collision8-Bit.ogg"
  ),
  MessageModel(
      id: '7',
      message: 'Good to hear that',
      timeSent: '10:06 AM',
      reactions: ['👍'],
      isMe: false,
      messageType: 1,
      isReplyMessage: false,
    senderData: ContactModel(name: "Marek", email: "marek@email.com", publicKey: "asd fasdfasdfa", imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"),
      audioPath: "https://rpg.hamsterrepublic.com/wiki-images/f/f1/BigBossDeath.ogg",
  ),
  MessageModel(
      id: '6',
      message: 'I am also fine',
      timeSent: '10:05 AM',
      reactions: ['👍', '❤️', '😂'],
      isMe: true,
      messageType: 0,
      isReplyMessage: true,
      originalMessage: originalMessage2,
      senderData: ContactModel(name: "Marek", email: "marek@email.com", publicKey: "asdfasdfasdfa", imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"),
      imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png"
  ),
  MessageModel(
      id: '5',
      message: 'What about you?',
      timeSent: '10:04 AM',
      reactions: ['👍'],
      isMe: false,
      messageType: 0,
      isReplyMessage: true,
      originalMessage: originalMessage1,
      senderData: ContactModel(name: "Marek", email: "marek@email.com", publicKey: "asd fasdfasdfa", imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"),
      imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"
  ),
  MessageModel(
    id: '4',
    content: 'I am fine, thank you',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 17)),
    sender: meContact,
    isMe: true,
    status: MessageStatus.read,
  ),
  MessageModel(
    id: '3',
    content: 'How are you?',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
    sender: marekContact,
    isMe: false,
    messageType: 0,
    senderData: ContactModel(name: "Marek", email: "marek@email.com", publicKey: "asd fasdfasdfa", imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"),
    isReplyMessage: false,
  ),
  MessageModel(
    id: '2',
    content: 'Hi',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 19)),
    sender: meContact,
    isMe: true,
    status: MessageStatus.read,
    reactions: [],
  ),
  MessageModel(
    id: '1',
    content: 'Hello',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    sender: marekContact,
    isMe: false,
    messageType: 0,
    senderData: ContactModel(name: "Marek", email: "marek@email.com", publicKey: "asd fasdfasdfa", imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"),
    isReplyMessage: false,
  ),
];

// Group chat messages
List<MessageModel> groupMessages = [
  MessageModel(
    id: '10',
    message: 'Goodbye',
    timeSent: '10:09 AM',
    reactions: [
      '👍',
    ],
    isMe: true,
    messageType: 0,
    isReplyMessage: false,
    senderData: ContactModel(name: "Me", email: "marek@email.com", publicKey: "asd fasdfasdfa", imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"),
  ),
  MessageModel(
    id: '9',
    content: 'Bye',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    sender: marekContact,
    isMe: false,
    messageType: 0,
    senderData: ContactModel(name: "Marek", email: "marek@email.com", publicKey: "asd fasdfasdfa", imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"),
    isReplyMessage: false,
  ),
  MessageModel(
      id: '8',
      message: 'Yes',
      timeSent: '10:07 AM',
      reactions: [],
      isMe: false,
      messageType: 0,
      isReplyMessage: false,
      senderData: ContactModel(name: "Marek", email: "marek@email.com", publicKey: "asd fasdfasdfa", imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"),
  ),
  MessageModel(
      id: '7',
      message: 'Good to hear that',
      timeSent: '10:06 AM',
      reactions: ['👍'],
      isMe: false,
      messageType: 0,
      isReplyMessage: false,
      senderData: ContactModel(name: "Marek", email: "marek@email.com", publicKey: "asd fasdfasdfa", imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"),

  ),
  MessageModel(
      id: '6',
      message: 'I am also fine',
      timeSent: '10:05 AM',
      reactions: ['👍', '❤️', '😂','👍','👍'],
      isMe: false,
      messageType: 0,
      isReplyMessage: false,
      senderData: ContactModel(name: "Max Hillebrand", email: "max@email.com", publicKey: "asdfasdfasdfa", imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png"),
      imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png"
  ),
  MessageModel(
      id: '2',
      message: 'Yooo. nice to be here',
      timeSent: '10:04 AM',
      reactions: ['👍'],
      isMe: false,
      messageType: 0,
      isReplyMessage: false,
      senderData: ContactModel(name: "Marek", email: "marek@email.com", publicKey: "asd fasdfasdfa", imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"),
  ),
  MessageModel(
    id: '1',
    content: 'Hey all. welcome to new group',
    type: MessageType.text,
    createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    sender: meContact,
    isMe: true,
    messageType: 0,
    isReplyMessage: false,
    senderData: ContactModel(name: "Me", email: "marek@email.com", publicKey: "asd fasdfasdfa", imagePath: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"),
  ),
];
