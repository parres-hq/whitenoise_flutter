// list of messages
import '../../../models/message.dart';

List<Message> messages = [
  Message(
      id: '12',
      message: '',
      timeSent: '10:04 AM',
      reactions: ['👍'],
      isMe: false,
      messageType: 0,
      isReplyMessage: false,
      imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"
  ),
  Message(
      id: '11',
      message: '',
      timeSent: '10:05 AM',
      reactions: ['👍', '❤️', '😂'],
      isMe: true,
      messageType: 0,
      isReplyMessage: false,
      imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png"
  ),

  Message(
    id: '10',
    message: 'Goodbye',
    timeSent: '10:09 AM',
    reactions: [
      '👍',
    ],
    isMe: true,
    messageType: 0,
    isReplyMessage: false,
  ),
  Message(
    id: '9',
    message: 'Bye',
    timeSent: '10:08 AM',
    reactions: ['👍', '💗', '😂'],
    isMe: false,
    messageType: 0,
    isReplyMessage: false,
  ),
  Message(
      id: '8',
      message: 'Yes',
      timeSent: '10:07 AM',
      reactions: ['❤️'],
      isMe: true,
      messageType: 1,
      isReplyMessage: false,
      audioPath: "https://commondatastorage.googleapis.com/codeskulptor-assets/Collision8-Bit.ogg"
  ),
  Message(
      id: '7',
      message: 'Good to hear that',
      timeSent: '10:06 AM',
      reactions: ['👍'],
      isMe: false,
      messageType: 1,
      isReplyMessage: false,
      audioPath: "https://commondatastorage.googleapis.com/codeskulptor-assets/Collision8-Bit.ogg"
  ),
  Message(
      id: '6',
      message: 'I am also fine',
      timeSent: '10:05 AM',
      reactions: ['👍', '❤️', '😂'],
      isMe: true,
      messageType: 0,
      isReplyMessage: true,
      originalMessage: "I am fine, thank you",
      originalUser: "Marek",
      imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png"
  ),
  Message(
      id: '5',
      message: 'What about you?',
      timeSent: '10:04 AM',
      reactions: ['👍'],
      isMe: false,
      messageType: 0,
      isReplyMessage: true,
      originalMessage: "I am fine, thank you",
      originalUser: "You",
      imageUrl: "https://civilogs.com/uploads/jobs/513/Site_photo_3_11_15_39.png"
  ),
  Message(
    id: '4',
    message: 'I am fine, thank you',
    timeSent: '10:03 AM',
    reactions: [],
    isMe: true,
    messageType: 0,
    isReplyMessage: false,
  ),
  Message(
    id: '3',
    message: 'How are you?',
    timeSent: '10:02 AM',
    reactions: [],
    isMe: false,
    messageType: 0,
    isReplyMessage: false,
  ),
  Message(
    id: '2',
    message: 'Hi',
    timeSent: '10:01 AM',
    reactions: ['😂'],
    isMe: true,
    messageType: 0,
    isReplyMessage: false,
  ),
  Message(
    id: '1',
    message: 'Hello',
    timeSent: '10:00 AM',
    reactions: ['😍'],
    isMe: false,
    messageType: 0,
    isReplyMessage: false,
  ),
];