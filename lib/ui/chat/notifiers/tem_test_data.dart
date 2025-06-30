// to be removed when not needed
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';

class ChatDatas {
  final String groupId;
  final List<MessageModel>? initialMessages;

  ChatDatas({
    required this.groupId,
    this.initialMessages,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatDatas &&
        other.groupId == groupId &&
        _listEquals(other.initialMessages, initialMessages);
  }

  @override
  int get hashCode => Object.hash(groupId, initialMessages);

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

ChatDatas testMessages() {
  final now = DateTime.now();
  final groupId = 'test_group';
  // Define test users
  final alice = User(
    id: 'alice_user',
    name: 'Alice Johnson',
    nip05: 'alice@nostr.com',
    publicKey: 'alice_public_key',
  );

  final bob = User(
    id: 'bob_user',
    name: 'Bob Smith',
    nip05: 'bob@example.org',
    publicKey: 'bob_public_key',
  );

  final charlie = User(
    id: 'charlie_user',
    name: 'Charlie Davis',
    nip05: 'charlie@domain.net',
    publicKey: 'charlie_public_key',
  );

  final diana = User(
    id: 'diana_user',
    name: 'Diana Wilson',
    nip05: 'dian@domain.net',
    publicKey: 'diana_public_key',
  );

  return ChatDatas(
    groupId: groupId,
    initialMessages: [
      MessageModel(
        id: 'test1',
        content: 'Hello everyone! Welcome to the group chat 👋',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(days: 2)),
        sender: alice,
        isMe: false,
        reactions: [
          Reaction(
            emoji: '👍',
            user: bob,
            createdAt: now.subtract(const Duration(hours: 1, minutes: 58)),
          ),
          Reaction(
            emoji: '👍',
            user: bob,
            createdAt: now.subtract(const Duration(hours: 1, minutes: 58)),
          ),
          Reaction(
            emoji: '👍',
            user: bob,
            createdAt: now.subtract(const Duration(hours: 1, minutes: 58)),
          ),
          Reaction(
            emoji: '🌷',
            user: bob,
            createdAt: now.subtract(const Duration(hours: 1, minutes: 58)),
          ),
          Reaction(
            emoji: '🎉',
            user: charlie,
            createdAt: now.subtract(const Duration(hours: 1, minutes: 55)),
          ),
        ],
      ),
      MessageModel(
        id: 'test1a',
        content: 'How are you all ?',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(hours: 2)),
        sender: alice,
        isMe: false,
        reactions: [
          Reaction(
            emoji: '👍',
            user: bob,
            createdAt: now.subtract(const Duration(hours: 1, minutes: 58)),
          ),
          Reaction(
            emoji: '🎉',
            user: charlie,
            createdAt: now.subtract(const Duration(hours: 1, minutes: 55)),
          ),
        ],
      ),
      MessageModel(
        id: 'test2',
        content: 'Hey Alice! Great to be here 😊',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
        sender: bob,
        isMe: true,
        status: MessageStatus.delivered,
        reactions: [
          Reaction(
            emoji: '👍',
            user: bob,
            createdAt: now.subtract(const Duration(hours: 1, minutes: 58)),
          ),
          Reaction(
            emoji: '🎉',
            user: charlie,
            createdAt: now.subtract(const Duration(hours: 1, minutes: 55)),
          ),
        ],
      ),
      MessageModel(
        id: 'test2933',
        content: 'we are goooooood!!!!!',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
        sender: bob,
        isMe: true,
        status: MessageStatus.delivered,
        reactions: [],
      ),

      MessageModel(
        id: 'test3',
        content:
            'This is a longer message to test how the chat handles text wrapping and longer content. Sometimes we need to send detailed explanations or longer thoughts that span multiple lines in the chat interface. It helps us understand how the UI behaves with various message lengths.',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
        sender: charlie,
        isMe: false,
        reactions: [
          Reaction(
            emoji: '📝',
            user: diana,
            createdAt: now.subtract(const Duration(hours: 1, minutes: 25)),
          ),
        ],
      ),
      MessageModel(
        id: 'test4',
        content: 'Quick question - what time is the meeting tomorrow?',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 15)),
        sender: diana,
        isMe: false,
        reactions: [],
      ),
      MessageModel(
        id: 'test5',
        content: 'The meeting is at 2 PM EST',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 10)),
        sender: alice,
        isMe: false,
        reactions: [
          Reaction(
            emoji: '✅',
            user: diana,
            createdAt: now.subtract(const Duration(hours: 1, minutes: 8)),
          ),
          Reaction(
            emoji: '👍',
            user: bob,
            createdAt: now.subtract(const Duration(hours: 1, minutes: 7)),
          ),
        ],
        replyTo: MessageModel(
          id: 'test4',
          content: 'Quick question - what time is the meeting tomorrow?',
          type: MessageType.text,
          createdAt: now.subtract(const Duration(hours: 1, minutes: 15)),
          sender: diana,
          isMe: false,
          reactions: [],
        ),
      ),
      MessageModel(
        id: 'test6',
        content: 'Perfect, thanks! 🙏',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 5)),
        sender: diana,
        isMe: false,
        reactions: [],
        replyTo: MessageModel(
          id: 'test5',
          content: 'The meeting is at 2 PM EST',
          type: MessageType.text,
          createdAt: now.subtract(const Duration(hours: 1, minutes: 10)),
          sender: alice,
          isMe: false,
          reactions: [],
        ),
      ),
      MessageModel(
        id: 'test7',
        content: 'Should I bring anything to the meeting?',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(minutes: 45)),
        sender: bob,
        isMe: true,
        status: MessageStatus.read,
        reactions: [],
      ),
      MessageModel(
        id: 'test8',
        content: 'Just bring your laptop and the quarterly reports 📊',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(minutes: 30)),
        sender: alice,
        isMe: false,
        reactions: [
          Reaction(
            emoji: '📋',
            user: charlie,
            createdAt: now.subtract(const Duration(minutes: 28)),
          ),
        ],
        replyTo: MessageModel(
          id: 'test7',
          content: 'Should I bring anything to the meeting?',
          type: MessageType.text,
          createdAt: now.subtract(const Duration(minutes: 45)),
          sender: bob,
          isMe: true,
          status: MessageStatus.read,
          reactions: [],
        ),
      ),
      MessageModel(
        id: 'test9',
        content: 'Got it! See you all tomorrow 👋',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(minutes: 15)),
        sender: charlie,
        isMe: false,
        reactions: [
          Reaction(
            emoji: '👋',
            user: alice,
            createdAt: now.subtract(const Duration(minutes: 13)),
          ),
          Reaction(emoji: '✨', user: diana, createdAt: now.subtract(const Duration(minutes: 12))),
        ],
      ),
      MessageModel(
        id: 'test10',
        content: 'Looking forward to it! 🚀',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(minutes: 5)),
        sender: bob,
        isMe: true,
        status: MessageStatus.sending,
        reactions: [],
      ),
      MessageModel(
        id: 'test11',
        type: MessageType.image,
        createdAt: now.subtract(const Duration(minutes: 3)),
        sender: charlie,
        isMe: false,
        imageUrl: 'https://picsum.photos/400/300',
        reactions: [
          Reaction(emoji: '📸', user: bob, createdAt: now.subtract(const Duration(minutes: 2))),
        ],
      ),
      MessageModel(
        id: 'test12',
        content: 'Nice photo! 📷',
        type: MessageType.text,
        createdAt: now.subtract(const Duration(minutes: 1)),
        sender: bob,
        isMe: true,
        status: MessageStatus.failed,
        reactions: [],
        replyTo: MessageModel(
          id: 'test11',
          type: MessageType.image,
          createdAt: now.subtract(const Duration(minutes: 3)),
          sender: charlie,
          isMe: false,
          imageUrl: 'https://picsum.photos/400/300',
          reactions: [],
        ),
      ),
    ],
  );
}
