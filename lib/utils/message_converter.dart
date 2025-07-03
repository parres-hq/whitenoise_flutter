import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/messages.dart';

/// Converts MessageWithTokensData to MessageModel for UI display
class MessageConverter {
  /// Converts a MessageWithTokensData to MessageModel
  static MessageModel fromMessageWithTokensData(
    MessageWithTokensData messageData, {
    required String? currentUserPublicKey,
    String? roomId,
    required Ref ref,
  }) {
    // Create a User object from the message sender
    final sender = User(
      id: messageData.pubkey,
      name: _getDisplayName(messageData.pubkey, currentUserPubkey: currentUserPublicKey, ref: ref),
      nip05: '',
      publicKey: messageData.pubkey,
    );

    // Determine if this message is from the current user
    final isMe = currentUserPublicKey != null && messageData.pubkey == currentUserPublicKey;

    // Convert BigInt timestamp to DateTime
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      messageData.createdAt.toInt() * 1000,
    );

    // Determine message status (default to sent for received messages)
    final status = isMe ? MessageStatus.sent : MessageStatus.delivered;

    return MessageModel(
      id: messageData.id,
      content: messageData.content,
      type: MessageType.text,
      createdAt: createdAt,
      sender: sender,
      isMe: isMe,
      groupId: roomId,
      status: status,
    );
  }

  /// Converts a list of MessageWithTokensData to MessageModel list
  static List<MessageModel> fromMessageWithTokensDataList(
    List<MessageWithTokensData> messageDataList, {
    required String? currentUserPublicKey,
    String? groupId,
    required Ref ref,
  }) {
    return messageDataList
        .map(
          (messageData) => fromMessageWithTokensData(
            messageData,
            currentUserPublicKey: currentUserPublicKey,
            roomId: groupId,
            ref: ref,
          ),
        )
        .toList();
  }

  /// Gets a display name for a public key
  /// Returns 'You' if pubkey matches current user, otherwise returns contact name or 'user'
  static String _getDisplayName(
    String pubkey, {
    String? currentUserPubkey,
    required Ref ref,
  }) {
    // If this is the current user, return 'You'
    if (currentUserPubkey != null && pubkey == currentUserPubkey) {
      return 'You';
    }

    // Try to find the contact name from the contact provider
    try {
      final contacts = ref.read(contactsProvider);
      final contactModels = contacts.contactModels ?? [];

      final contact = contactModels.where((contact) => contact.publicKey == pubkey).toList();

      if (contact.isNotEmpty) {
        // Return displayName if available, otherwise name
        return contact.first.displayName?.isNotEmpty == true
            ? contact.first.displayName!
            : contact.first.name;
      }
    } catch (e) {
      // Continue to fallback if contact lookup fails
    }

    // Return 'user' if contact not found
    return 'user';
  }
}
