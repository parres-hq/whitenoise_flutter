import 'package:whitenoise/domain/models/chat_model.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';

final List<ChatModel> dummyChats = [
  ChatModel(
    id: '1',
    name: 'Jeff',
    lastMessage: 'I know',
    time: 'Now',
    unreadCount: 1,
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    id: '2',
    name: 'Max',
    lastMessage: 'Invite to join a private chat',
    time: '15:34',
    hasAttachment: true,
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    id: '3',
    name: 'jstaab',
    lastMessage:
        'I think I might have found part of the issue with those key packages. 😎',
    time: '11:07',
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    id: '4',
    name: 'White Noise',
    lastMessage: 'Max: Nice',
    time: '09:46',
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    id: '5',
    name: 'AB24 Speakers',
    lastMessage: 'Brandon: https://x.com/Greencandlelt/...',
    time: '01:49',
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    id: '6',
    name: 'WWA',
    lastMessage: 'Kacper: 🇵🇱 ja mam kaca szczerze',
    time: 'Mon',
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    id: '7',
    name: 'Mama',
    lastMessage: 'A święta gdzie planujesz ?',
    time: 'Mon',
    unreadCount: 2,
    imagePath: '',
  ),
  ChatModel(
    id: '8',
    name: 'Justyna',
    lastMessage: 'Fajne',
    time: 'Fri',
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    id: '9',
    name: 'Marek',
    lastMessage: 'Lorem ipsum dolor sit amet, consectetur',
    time: '15:34',
    imagePath: AssetsPaths.icImage,
  ),
];
