// list of messages
import 'package:whitenoise/domain/models/contact_model.dart';

import '../models/message_model.dart';

MessageModel originalMessage1 = MessageModel(
  id: '100',
  message: 'I am also fine',
  timeSent: '10:05 AM',
  reactions: ['👍', '❤️', '😂'],
  isMe: true,
  messageType: 0,
  isReplyMessage: false,
  senderData: ContactModel(
    name: "Marek",
    email: "marek@email.com",
    publicKey: "asdfasdfasdfa",
    imagePath:
        "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
  ),
  imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png",
);

MessageModel originalMessage2 = MessageModel(
  id: '101',
  message: 'Good to hear that',
  timeSent: '10:05 AM',
  reactions: ['👍'],
  isMe: false,
  messageType: 0,
  isReplyMessage: false,
  senderData: ContactModel(
    name: "Marek",
    email: "marek@email.com",
    publicKey: "asdfasdfasdfa",
    imagePath:
        "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
  ),
  imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png",
);

List<MessageModel> messages = [
  MessageModel(
    id: '12',
    message: '',
    timeSent: '10:04 AM',
    reactions: ['👍'],
    isMe: false,
    messageType: 0,
    isReplyMessage: false,
    imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
  ),
  MessageModel(
    id: '11',
    message: '',
    timeSent: '10:05 AM',
    reactions: ['👍', '❤️', '😂'],
    isMe: true,
    messageType: 0,
    isReplyMessage: false,
    imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png",
  ),

  MessageModel(
    id: '10',
    message: 'Goodbye',
    timeSent: '10:09 AM',
    reactions: ['👍'],
    isMe: true,
    messageType: 0,
    isReplyMessage: false,
  ),
  MessageModel(
    id: '9',
    message: 'Bye',
    timeSent: '10:08 AM',
    reactions: ['👍', '💗', '😂'],
    isMe: false,
    messageType: 0,
    isReplyMessage: false,
  ),
  MessageModel(
    id: '8',
    message: 'Yes',
    timeSent: '10:07 AM',
    reactions: ['❤️'],
    isMe: true,
    messageType: 1,
    isReplyMessage: false,
    audioPath:
        "https://commondatastorage.googleapis.com/codeskulptor-assets/Collision8-Bit.ogg",
  ),
  MessageModel(
    id: '7',
    message: 'Good to hear that',
    timeSent: '10:06 AM',
    reactions: ['👍'],
    isMe: false,
    messageType: 1,
    isReplyMessage: false,
    senderData: ContactModel(
      name: "Marek",
      email: "marek@email.com",
      publicKey: "asd fasdfasdfa",
      imagePath:
          "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
    ),
    audioPath:
        "https://rpg.hamsterrepublic.com/wiki-images/f/f1/BigBossDeath.ogg",
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
    senderData: ContactModel(
      name: "Marek",
      email: "marek@email.com",
      publicKey: "asdfasdfasdfa",
      imagePath:
          "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
    ),
    imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png",
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
    senderData: ContactModel(
      name: "Marek",
      email: "marek@email.com",
      publicKey: "asd fasdfasdfa",
      imagePath:
          "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
    ),
    imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
  ),
  MessageModel(
    id: '4',
    message: 'I am fine, thank you',
    timeSent: '10:03 AM',
    reactions: [],
    isMe: true,
    messageType: 0,
    isReplyMessage: false,
  ),
  MessageModel(
    id: '3',
    message: 'How are you?',
    timeSent: '10:02 AM',
    reactions: [],
    isMe: false,
    messageType: 0,
    senderData: ContactModel(
      name: "Marek",
      email: "marek@email.com",
      publicKey: "asd fasdfasdfa",
      imagePath:
          "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
    ),
    isReplyMessage: false,
  ),
  MessageModel(
    id: '2',
    message: 'Hi',
    timeSent: '10:01 AM',
    reactions: ['😂'],
    isMe: true,
    messageType: 0,
    isReplyMessage: false,
  ),
  MessageModel(
    id: '1',
    message: 'Hello',
    timeSent: '10:00 AM',
    reactions: ['😍'],
    isMe: false,
    messageType: 0,
    senderData: ContactModel(
      name: "Marek",
      email: "marek@email.com",
      publicKey: "asd fasdfasdfa",
      imagePath:
          "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
    ),
    isReplyMessage: false,
  ),
];

List<MessageModel> groupMessages = [
  MessageModel(
    id: '10',
    message: 'Goodbye',
    timeSent: '10:09 AM',
    reactions: ['👍'],
    isMe: true,
    messageType: 0,
    isReplyMessage: false,
    senderData: ContactModel(
      name: "Me",
      email: "marek@email.com",
      publicKey: "asd fasdfasdfa",
      imagePath:
          "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
    ),
  ),
  MessageModel(
    id: '9',
    message: 'Bye',
    timeSent: '10:08 AM',
    reactions: ['👍', '💗', '😂'],
    isMe: false,
    messageType: 0,
    senderData: ContactModel(
      name: "Marek",
      email: "marek@email.com",
      publicKey: "asd fasdfasdfa",
      imagePath:
          "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
    ),
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
    senderData: ContactModel(
      name: "Marek",
      email: "marek@email.com",
      publicKey: "asd fasdfasdfa",
      imagePath:
          "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
    ),
  ),
  MessageModel(
    id: '7',
    message: 'Good to hear that',
    timeSent: '10:06 AM',
    reactions: ['👍'],
    isMe: false,
    messageType: 0,
    isReplyMessage: false,
    senderData: ContactModel(
      name: "Marek",
      email: "marek@email.com",
      publicKey: "asd fasdfasdfa",
      imagePath:
          "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
    ),
  ),
  MessageModel(
    id: '6',
    message: 'I am also fine',
    timeSent: '10:05 AM',
    reactions: ['👍', '❤️', '😂', '👍', '👍'],
    isMe: false,
    messageType: 0,
    isReplyMessage: false,
    senderData: ContactModel(
      name: "Max Hillebrand",
      email: "max@email.com",
      publicKey: "asdfasdfasdfa",
      imagePath:
          "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png",
    ),
    imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png",
  ),
  MessageModel(
    id: '2',
    message: 'Yooo. nice to be here',
    timeSent: '10:04 AM',
    reactions: ['👍'],
    isMe: false,
    messageType: 0,
    isReplyMessage: false,
    senderData: ContactModel(
      name: "Marek",
      email: "marek@email.com",
      publicKey: "asd fasdfasdfa",
      imagePath:
          "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
    ),
  ),
  MessageModel(
    id: '1',
    message: 'Hey all. welcome to new group',
    timeSent: '10:00 AM',
    reactions: ['😍'],
    isMe: true,
    messageType: 0,
    isReplyMessage: false,
    senderData: ContactModel(
      name: "Me",
      email: "marek@email.com",
      publicKey: "asd fasdfasdfa",
      imagePath:
          "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png",
    ),
  ),
];
