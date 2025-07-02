use flutter_rust_bridge::frb;
pub use whitenoise::{
    ChatMessage, MessageWithTokens, PublicKey, ReactionSummary, SerializableToken, Tag, Whitenoise,
    WhitenoiseError,
};

#[derive(Debug, Clone)]
pub struct MessageWithTokensData {
    pub id: String,
    pub pubkey: String,
    pub kind: u16,
    pub created_at: u64,
    pub content: Option<String>,
    pub tokens: Vec<String>, // Simplified tokens representation
}

#[derive(Debug, Clone)]
pub struct ChatMessageData {
    pub id: String,
    pub pubkey: String,
    pub content: String,
    pub created_at: u64,
    pub tags: Vec<String>, // Simplified tags representation for Flutter
    pub is_reply: bool,
    pub reply_to_id: Option<String>,
    pub is_deleted: bool,
    pub content_tokens: Vec<SerializableTokenData>,
    pub reactions: ReactionSummaryData,
    pub kind: u16,
}

/// Flutter-compatible reaction summary
#[derive(Debug, Clone)]
pub struct ReactionSummaryData {
    pub by_emoji: Vec<EmojiReactionData>,
    pub user_reactions: Vec<UserReactionData>,
}

/// Flutter-compatible emoji reaction details
#[derive(Debug, Clone)]
pub struct EmojiReactionData {
    pub emoji: String,
    pub count: u64,         // Using u64 for Flutter compatibility
    pub users: Vec<String>, // PublicKey converted to hex strings
}

/// Flutter-compatible user reaction
#[derive(Debug, Clone)]
pub struct UserReactionData {
    pub user: String, // PublicKey converted to hex string
    pub emoji: String,
    pub created_at: u64, // Timestamp converted to u64
}

/// Flutter-compatible serializable token
#[derive(Debug, Clone)]
pub struct SerializableTokenData {
    pub token_type: String, // "Nostr", "Url", "Hashtag", "Text", "LineBreak", "Whitespace"
    pub content: Option<String>, // None for LineBreak and Whitespace
}

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
#[frb]
pub fn convert_message_with_tokens_to_data(
    message_with_tokens: &MessageWithTokens,
) -> MessageWithTokensData {
    // Convert tokens to simplified string representation
    let tokens = message_with_tokens
        .tokens
        .iter()
        .map(|token| format!("{token:?}"))
        .collect();

    MessageWithTokensData {
        id: message_with_tokens.message.id.to_hex(),
        pubkey: message_with_tokens.message.pubkey.to_hex(),
        kind: message_with_tokens.message.kind.as_u16(),
        created_at: message_with_tokens.message.created_at.as_u64(),
        content: Some(message_with_tokens.message.content.clone()),
        tokens,
    }
}

/// Helper function to convert SerializableToken to SerializableTokenData
fn convert_serializable_token(token: &SerializableToken) -> SerializableTokenData {
    match token {
        SerializableToken::Nostr(s) => SerializableTokenData {
            token_type: "Nostr".to_string(),
            content: Some(s.clone()),
        },
        SerializableToken::Url(s) => SerializableTokenData {
            token_type: "Url".to_string(),
            content: Some(s.clone()),
        },
        SerializableToken::Hashtag(s) => SerializableTokenData {
            token_type: "Hashtag".to_string(),
            content: Some(s.clone()),
        },
        SerializableToken::Text(s) => SerializableTokenData {
            token_type: "Text".to_string(),
            content: Some(s.clone()),
        },
        SerializableToken::LineBreak => SerializableTokenData {
            token_type: "LineBreak".to_string(),
            content: None,
        },
        SerializableToken::Whitespace => SerializableTokenData {
            token_type: "Whitespace".to_string(),
            content: None,
        },
    }
}

/// Helper function to convert ReactionSummary to ReactionSummaryData
fn convert_reaction_summary(reactions: &ReactionSummary) -> ReactionSummaryData {
    let by_emoji = reactions
        .by_emoji
        .iter()
        .map(|(emoji, reaction)| EmojiReactionData {
            emoji: emoji.clone(),
            count: reaction.count as u64,
            users: reaction.users.iter().map(|pk| pk.to_hex()).collect(),
        })
        .collect();

    let user_reactions = reactions
        .user_reactions
        .iter()
        .map(|user_reaction| UserReactionData {
            user: user_reaction.user.to_hex(),
            emoji: user_reaction.emoji.clone(),
            created_at: user_reaction.created_at.as_u64(),
        })
        .collect();

    ReactionSummaryData {
        by_emoji,
        user_reactions,
    }
}

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
#[frb]
pub fn convert_chat_message_to_data(chat_message: &ChatMessage) -> ChatMessageData {
    // Convert tags to simplified string representation
    let tags = chat_message
        .tags
        .iter()
        .map(|tag| format!("{tag:?}"))
        .collect();

    // Convert content tokens to proper Flutter-compatible structs
    let content_tokens = chat_message
        .content_tokens
        .iter()
        .map(convert_serializable_token)
        .collect();

    // Convert reactions to proper Flutter-compatible struct
    let reactions = convert_reaction_summary(&chat_message.reactions);

    ChatMessageData {
        id: chat_message.id.clone(),
        pubkey: chat_message.author.to_hex(),
        content: chat_message.content.clone(),
        created_at: chat_message.created_at.as_u64(),
        tags,
        is_reply: chat_message.is_reply,
        reply_to_id: chat_message.reply_to_id.clone(),
        is_deleted: chat_message.is_deleted,
        content_tokens,
        reactions,
        kind: chat_message.kind,
    }
}

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
#[frb]
pub async fn send_message_to_group(
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
    message: String,
    kind: u16,
    tags: Option<Vec<Tag>>,
) -> Result<MessageWithTokensData, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey_clone = *pubkey;
    let message_with_tokens = tokio::task::spawn_blocking(move || {
        tokio::runtime::Handle::current().block_on(whitenoise.send_message_to_group(
            &pubkey_clone,
            &group_id,
            message,
            kind,
            tags,
        ))
    })
    .await
    .map_err(|e| WhitenoiseError::from(std::io::Error::other(e)))??;
    Ok(convert_message_with_tokens_to_data(&message_with_tokens))
}

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
#[frb]
pub async fn fetch_messages_for_group(
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
) -> Result<Vec<MessageWithTokensData>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let messages = whitenoise
        .fetch_messages_for_group(pubkey, &group_id)
        .await?;
    Ok(messages
        .iter()
        .map(convert_message_with_tokens_to_data)
        .collect())
}

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
#[frb]
pub async fn fetch_aggregated_messages_for_group(
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
) -> Result<Vec<ChatMessageData>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let messages = whitenoise
        .fetch_aggregated_messages_for_group(pubkey, &group_id)
        .await?;
    Ok(messages.iter().map(convert_chat_message_to_data).collect())
}
