import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/messages.dart';

/// Converts MessageWithTokensData to MessageModel for UI display
class MessageConverter {
  /// Converts a MessageWithTokensData to MessageModel
  static Future<MessageModel> fromMessageWithTokensData(
    MessageWithTokensData messageData, {
    required String? currentUserPublicKey,
    String? groupId,
    required Ref ref,
  }) async {
    // Determine if this message is from the current user
    final isMe = currentUserPublicKey != null && messageData.pubkey == currentUserPublicKey;

    // Create a User object from the message sender using metadata
    final sender = await _createUserFromMetadata(
      messageData.pubkey,
      currentUserPubkey: currentUserPublicKey,
      ref: ref,
    );

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
      groupId: groupId,
      status: status,
    );
  }

  /// Converts a list of MessageWithTokensData to MessageModel list
  static Future<List<MessageModel>> fromMessageWithTokensDataList(
    List<MessageWithTokensData> messageDataList, {
    required String? currentUserPublicKey,
    String? groupId,
    required Ref ref,
  }) async {
    final List<MessageModel> messages = [];

    for (final messageData in messageDataList) {
      final message = await fromMessageWithTokensData(
        messageData,
        currentUserPublicKey: currentUserPublicKey,
        groupId: groupId,
        ref: ref,
      );
      messages.add(message);
    }

    return messages;
  }

  /// Creates a User object from metadata
  static Future<User> _createUserFromMetadata(
    String pubkey, {
    String? currentUserPubkey,
    required Ref ref,
  }) async {
    // If this is the current user, return 'You'
    if (currentUserPubkey != null && pubkey == currentUserPubkey) {
      return User(
        id: pubkey,
        name: 'You',
        nip05: '',
        publicKey: pubkey,
      );
    }

    try {
      // Try to get metadata from the metadata cache
      final metadataCache = ref.read(metadataCacheProvider.notifier);
      final contactModel = await metadataCache.getContactModel(pubkey);

      return User(
        id: pubkey,
        name: contactModel.displayNameOrName,
        nip05: contactModel.nip05 ?? '',
        publicKey: pubkey,
        imagePath: contactModel.imagePath,
        username: contactModel.displayName,
      );
    } catch (e) {
      // Fallback to contact provider if metadata cache fails
      return _createUserFromContactProvider(pubkey, ref: ref);
    }
  }

  /// Fallback method to create User from contact provider
  static User _createUserFromContactProvider(String pubkey, {required Ref ref}) {
    try {
      final contacts = ref.read(contactsProvider);
      final contactModels = contacts.contactModels ?? [];

      final contact = contactModels.where((contact) => contact.publicKey == pubkey).toList();

      if (contact.isNotEmpty) {
        final contactModel = contact.first;
        return User(
          id: pubkey,
          name:
              contactModel.displayName?.isNotEmpty == true
                  ? contactModel.displayName!
                  : contactModel.name,
          nip05: contactModel.nip05 ?? '',
          publicKey: pubkey,
          imagePath: contactModel.imagePath,
          username: contactModel.displayName,
        );
      }
    } catch (e) {
      // Continue to fallback if contact lookup fails
    }

    // Return fallback user if contact not found
    return User(
      id: pubkey,
      name: 'Unknown User',
      nip05: '',
      publicKey: pubkey,
    );
  }
}
