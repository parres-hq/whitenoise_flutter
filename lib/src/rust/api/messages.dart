// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.11.1.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import '../api.dart';
import '../frb_generated.dart';
import 'accounts.dart';
import 'groups.dart';

// These functions are ignored because they are not marked as `pub`: `convert_reaction_summary`, `convert_serializable_token`
// These function are ignored because they are on traits that is not defined in current crate (put an empty `#[frb]` on it to unignore): `clone`, `clone`, `clone`, `clone`, `clone`, `clone`, `fmt`, `fmt`, `fmt`, `fmt`, `fmt`, `fmt`

/// Converts a core `MessageWithTokens` object to a Flutter-compatible `MessageWithTokensData` structure.
///
/// This function handles the conversion of complex message and token data to Flutter-compatible
/// formats, converting timestamps, public keys, and tokens to their string representations.
///
/// # Parameters
/// * `message_with_tokens` - Reference to a MessageWithTokens object from the core library
///
/// # Returns
/// A MessageWithTokensData struct with all fields converted for Flutter compatibility
///
/// # Notes
/// * Tokens are converted to debug string representations for simplicity
/// * All IDs and public keys are converted to hex format
/// * Timestamps are converted to u64 for JavaScript compatibility
Future<MessageWithTokensData> convertMessageWithTokensToData({
  required MessageWithTokens messageWithTokens,
}) => RustLib.instance.api.crateApiMessagesConvertMessageWithTokensToData(
  messageWithTokens: messageWithTokens,
);

/// Converts a core `ChatMessage` object to a Flutter-compatible `ChatMessageData` structure.
///
/// This function handles the conversion of chat message data to Flutter-compatible
/// formats, converting timestamps, public keys to their string representations.
///
/// # Parameters
/// * `chat_message` - Reference to a ChatMessage object from the core library
///
/// # Returns
/// A ChatMessageData struct with all fields converted for Flutter compatibility
///
/// # Notes
/// * All IDs and public keys are converted to hex format
/// * Timestamps are converted to u64 for JavaScript compatibility
/// * Complex types (tokens, reactions) are converted to Flutter-compatible structs
Future<ChatMessageData> convertChatMessageToData({
  required ChatMessage chatMessage,
}) => RustLib.instance.api.crateApiMessagesConvertChatMessageToData(
  chatMessage: chatMessage,
);

/// Send a message to a group
///
/// This method sends a message to the specified group using the MLS protocol.
/// The message will be encrypted and delivered to all group members.
///
/// # Arguments
/// * `pubkey` - The public key of the account sending the message
/// * `group_id` - The MLS group ID to send the message to
/// * `message` - The message content as a string
/// * `kind` - The Nostr event kind (e.g., 1 for text message, 5 for delete)
/// * `tags` - Optional Nostr tags to include with the message (use the `tag_from_vec` helper function to convert a vec of strings to a tag)
///
/// # Returns
/// * `Ok(MessageWithTokensData)` - The sent message and parsed tokens if successful
/// * `Err(WhitenoiseError)` - If there was an error sending the message
Future<MessageWithTokensData> sendMessageToGroup({
  required PublicKey pubkey,
  required GroupId groupId,
  required String message,
  required int kind,
  List<Tag>? tags,
}) => RustLib.instance.api.crateApiMessagesSendMessageToGroup(
  pubkey: pubkey,
  groupId: groupId,
  message: message,
  kind: kind,
  tags: tags,
);

/// Fetches all messages for a specific MLS group.
///
/// This function retrieves messages that have been sent to the specified group,
/// including the decrypted content and associated token data for each message.
/// The messages are returned with their complete token representation, which
/// can be useful for debugging and understanding the message structure.
///
/// # Arguments
///
/// * `pubkey` - The public key of the account requesting the messages. This account
///   must be a member of the specified group to successfully fetch messages.
/// * `group_id` - The unique identifier of the MLS group to fetch messages from.
///
/// # Returns
///
/// Returns a `Result` containing:
/// - `Ok(Vec<MessageWithTokensData>)` - A vector of messages with their token data
/// - `Err(WhitenoiseError)` - If the operation fails (e.g., network error, access denied,
///   group not found, or user not a member of the group)
///
/// # Examples
///
/// ```rust
/// use whitenoise::PublicKey;
///
/// // Fetch messages for a group
/// let pubkey = PublicKey::from_string("npub1...")?;
/// let group_id = GroupId::from_hex("abc123...")?;
/// let messages = fetch_messages_for_group(&pubkey, group_id).await?;
///
/// println!("Fetched {} messages", messages.len());
/// for (i, message) in messages.iter().enumerate() {
///     println!("Message {}: {} tokens", i + 1, message.tokens.len());
/// }
/// ```
///
/// # Notes
///
/// - Messages are returned in chronological order (oldest first)
/// - Each message includes both the decrypted content and token representation
/// - Only group members can fetch messages from a group
/// - The token data should be used to construct the message content.
Future<List<MessageWithTokensData>> fetchMessagesForGroup({
  required PublicKey pubkey,
  required GroupId groupId,
}) => RustLib.instance.api.crateApiMessagesFetchMessagesForGroup(
  pubkey: pubkey,
  groupId: groupId,
);

/// Fetches aggregated messages for a specific MLS group.
///
/// This function retrieves and processes messages for the specified group, returning
/// them as aggregated `ChatMessage` objects. Unlike `fetch_messages_for_group`, which
/// returns raw messages with token data, this function processes the messages into
/// their final chat format, handling message threading, reactions, deletions, and
/// other message operations to provide a clean, aggregated view of the conversation.
///
/// The aggregation process includes:
/// - Combining message edits with their original messages
/// - Processing message deletions and marking messages as deleted
/// - Handling message reactions and their associations
/// - Resolving message threads and reply relationships
/// - Converting token-based content into final display format
///
/// # Arguments
///
/// * `pubkey` - The public key of the account requesting the messages. This account
///   must be a member of the specified group to successfully fetch messages.
/// * `group_id` - The unique identifier of the MLS group to fetch aggregated messages from.
///
/// # Returns
///
/// Returns a `Result` containing:
/// - `Ok(Vec<ChatMessage>)` - A vector of processed chat messages ready for display
/// - `Err(WhitenoiseError)` - If the operation fails (e.g., network error, access denied,
///   group not found, user not a member of the group, or message processing error)
///
/// # Examples
///
/// ```rust
/// use whitenoise::PublicKey;
///
/// // Fetch aggregated messages for a group
/// let pubkey = PublicKey::from_string("npub1...")?;
/// let group_id = GroupId::from_hex("abc123...")?;
/// let chat_messages = fetch_aggregated_messages_for_group(&pubkey, group_id).await?;
///
/// println!("Fetched {} chat messages", chat_messages.len());
/// for message in chat_messages {
///     println!("Message from {}: {}", message.pubkey, message.content);
/// }
/// ```
///
/// # Notes
///
/// - Messages are returned in chronological order (oldest first)
/// - Deleted messages may still be present but marked as deleted
/// - Edited messages show their latest version
/// - This function is preferred for UI display as it provides processed chat data
/// - Use `fetch_messages_for_group` if you need access to raw message tokens
/// - Only group members can fetch messages from a group
Future<List<ChatMessageData>> fetchAggregatedMessagesForGroup({
  required PublicKey pubkey,
  required GroupId groupId,
}) => RustLib.instance.api.crateApiMessagesFetchAggregatedMessagesForGroup(
  pubkey: pubkey,
  groupId: groupId,
);

/// Send an encrypted direct message using NIP-04
///
/// This method sends a private direct message to another user using the NIP-04 encryption
/// standard. The message content is encrypted using ECDH (Elliptic Curve Diffie-Hellman)
/// key exchange between the sender and receiver, ensuring that only the intended recipient
/// can decrypt and read the message content.
///
/// NIP-04 is the Nostr standard for encrypted direct messages, providing end-to-end encryption
/// for private communications. The encryption uses the sender's private key and the receiver's
/// public key to create a shared secret, which is then used to encrypt the message content.
///
/// # Arguments
///
/// * `sender` - The public key of the account sending the message. The corresponding private
///   key must be available in the account's keystore to perform the encryption.
/// * `receiver` - The public key of the intended recipient. This is used to derive the shared
///   encryption key for the message.
/// * `content` - The message content as a plaintext string. This will be encrypted before
///   being sent to the Nostr network.
/// * `tags` - Nostr tags to include with the encrypted message. These tags are not
///   encrypted and will be visible in the Nostr event. Use the `tag_from_vec` helper function
///   to convert a vec of strings to a tag if needed.
///
/// # Returns
///
/// Returns a `Result` containing:
/// - `Ok(())` - If the message was successfully encrypted and sent
/// - `Err(WhitenoiseError)` - If the operation fails (e.g., network error, encryption failure,
///   sender's private key not found, or invalid recipient public key)
///
/// # Examples
///
/// ```rust
/// use whitenoise::PublicKey;
///
/// // Send a simple direct message
/// let sender = PublicKey::from_string("npub1sender...")?;
/// let receiver = PublicKey::from_string("npub1receiver...")?;
/// let content = "Hello, this is a private message!".to_string();
///
/// send_direct_message_nip04(&sender, &receiver, content, None).await?;
///
/// // Send a direct message with tags
/// let tags = vec![tag_from_vec(vec!["reply".to_string(), "event_id".to_string()])];
/// send_direct_message_nip04(&sender, &receiver, content, Some(tags)).await?;
/// ```
///
/// # Notes
///
/// - The message content is encrypted using NIP-04 standard encryption
/// - The sender's private key must be available in the account's keystore
/// - Tags are not encrypted and remain visible in the Nostr event
/// - The encrypted message is broadcast to configured Nostr relays
/// - Recipients must have NIP-04 support to decrypt and read the message
/// - Message delivery depends on the recipient being connected to common relays
/// - This method does not return the sent message data; use group messaging if you need
///   message tracking and token analysis
Future<void> sendDirectMessageNip04({
  required PublicKey sender,
  required PublicKey receiver,
  required String content,
  required List<Tag> tags,
}) => RustLib.instance.api.crateApiMessagesSendDirectMessageNip04(
  sender: sender,
  receiver: receiver,
  content: content,
  tags: tags,
);

// Rust type: RustOpaqueMoi<flutter_rust_bridge::for_generated::RustAutoOpaqueInner<ChatMessage>>
abstract class ChatMessage implements RustOpaqueInterface {}

// Rust type: RustOpaqueMoi<flutter_rust_bridge::for_generated::RustAutoOpaqueInner<MessageWithTokens>>
abstract class MessageWithTokens implements RustOpaqueInterface {}

// Rust type: RustOpaqueMoi<flutter_rust_bridge::for_generated::RustAutoOpaqueInner<Tag>>
abstract class Tag implements RustOpaqueInterface {}

class ChatMessageData {
  final String id;
  final String pubkey;
  final String content;
  final BigInt createdAt;
  final List<String> tags;
  final bool isReply;
  final String? replyToId;
  final bool isDeleted;
  final List<SerializableTokenData> contentTokens;
  final ReactionSummaryData reactions;
  final int kind;

  const ChatMessageData({
    required this.id,
    required this.pubkey,
    required this.content,
    required this.createdAt,
    required this.tags,
    required this.isReply,
    this.replyToId,
    required this.isDeleted,
    required this.contentTokens,
    required this.reactions,
    required this.kind,
  });

  @override
  int get hashCode =>
      id.hashCode ^
      pubkey.hashCode ^
      content.hashCode ^
      createdAt.hashCode ^
      tags.hashCode ^
      isReply.hashCode ^
      replyToId.hashCode ^
      isDeleted.hashCode ^
      contentTokens.hashCode ^
      reactions.hashCode ^
      kind.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pubkey == other.pubkey &&
          content == other.content &&
          createdAt == other.createdAt &&
          tags == other.tags &&
          isReply == other.isReply &&
          replyToId == other.replyToId &&
          isDeleted == other.isDeleted &&
          contentTokens == other.contentTokens &&
          reactions == other.reactions &&
          kind == other.kind;
}

/// Flutter-compatible emoji reaction details
class EmojiReactionData {
  final String emoji;
  final BigInt count;
  final List<String> users;

  const EmojiReactionData({
    required this.emoji,
    required this.count,
    required this.users,
  });

  @override
  int get hashCode => emoji.hashCode ^ count.hashCode ^ users.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmojiReactionData &&
          runtimeType == other.runtimeType &&
          emoji == other.emoji &&
          count == other.count &&
          users == other.users;
}

class MessageWithTokensData {
  final String id;
  final String pubkey;
  final int kind;
  final BigInt createdAt;
  final String? content;
  final List<String> tokens;

  const MessageWithTokensData({
    required this.id,
    required this.pubkey,
    required this.kind,
    required this.createdAt,
    this.content,
    required this.tokens,
  });

  @override
  int get hashCode =>
      id.hashCode ^
      pubkey.hashCode ^
      kind.hashCode ^
      createdAt.hashCode ^
      content.hashCode ^
      tokens.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageWithTokensData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pubkey == other.pubkey &&
          kind == other.kind &&
          createdAt == other.createdAt &&
          content == other.content &&
          tokens == other.tokens;
}

/// Flutter-compatible reaction summary
class ReactionSummaryData {
  final List<EmojiReactionData> byEmoji;
  final List<UserReactionData> userReactions;

  const ReactionSummaryData({
    required this.byEmoji,
    required this.userReactions,
  });

  @override
  int get hashCode => byEmoji.hashCode ^ userReactions.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReactionSummaryData &&
          runtimeType == other.runtimeType &&
          byEmoji == other.byEmoji &&
          userReactions == other.userReactions;
}

/// Flutter-compatible serializable token
class SerializableTokenData {
  final String tokenType;
  final String? content;

  const SerializableTokenData({
    required this.tokenType,
    this.content,
  });

  @override
  int get hashCode => tokenType.hashCode ^ content.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SerializableTokenData &&
          runtimeType == other.runtimeType &&
          tokenType == other.tokenType &&
          content == other.content;
}

/// Flutter-compatible user reaction
class UserReactionData {
  final String user;
  final String emoji;
  final BigInt createdAt;

  const UserReactionData({
    required this.user,
    required this.emoji,
    required this.createdAt,
  });

  @override
  int get hashCode => user.hashCode ^ emoji.hashCode ^ createdAt.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserReactionData &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          emoji == other.emoji &&
          createdAt == other.createdAt;
}
