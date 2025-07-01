use flutter_rust_bridge::frb;
pub use whitenoise::{MessageWithTokens, PublicKey, Tag, Whitenoise, WhitenoiseError};

#[derive(Debug, Clone)]
pub struct MessageWithTokensData {
    pub id: String,
    pub pubkey: String,
    pub kind: u16,
    pub created_at: u64,
    pub content: Option<String>,
    pub tokens: Vec<String>, // Simplified tokens representation
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
