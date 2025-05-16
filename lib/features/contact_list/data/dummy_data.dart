import 'package:whitenoise/core/utils/assets_paths.dart';
import 'package:whitenoise/features/contact_list/models/chat_model.dart';

// Dummy contacts for search results
final List<ChatModel> dummyContacts = [
  ChatModel(
    name: 'Max Hillebrand',
    lastMessage: '',
    time: '',
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    name: 'Max DeMarco',
    lastMessage: '',
    time: '',
    imagePath: AssetsPaths.icImage,
  ),
];

final List<ChatModel> dummyChats = [
  ChatModel(
    name: 'Jeff',
    lastMessage: 'I know',
    time: 'Now',
    unreadCount: 1,
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    name: 'Max',
    lastMessage: 'Invite to join a private chat',
    time: '15:34',
    hasAttachment: true,
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    name: 'jstaab',
    lastMessage: 'I think I might have found part of the issue with those key packages. 😎',
    time: '11:07',
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    name: 'White Noise',
    lastMessage: 'Max: Nice',
    time: '09:46',
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    name: 'AB24 Speakers',
    lastMessage: 'Brandon: https://x.com/Greencandlelt/...',
    time: '01:49',
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    name: 'WWA',
    lastMessage: 'Kacper: 🇵🇱 ja mam kaca szczerze',
    time: 'Mon',
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    name: 'Mama',
    lastMessage: 'A święta gdzie planujesz ?',
    time: 'Mon',
    unreadCount: 2,
    imagePath: '',
  ),
  ChatModel(
    name: 'Justyna',
    lastMessage: 'Fajne',
    time: 'Fri',
    imagePath: AssetsPaths.icImage,
  ),
  ChatModel(
    name: 'Marek',
    lastMessage: 'Lorem ipsum dolor sit amet, consectetur',
    time: '15:34',
    imagePath: AssetsPaths.icImage,
  ),
];
