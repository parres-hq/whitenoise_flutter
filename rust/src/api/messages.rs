use crate::api::{
    error::ApiError,
    media_files::MediaFile,
    utils::{group_id_from_string, group_id_to_string},
};
use crate::frb_generated::StreamSink;
use chrono::{DateTime, TimeZone, Utc};
use flutter_rust_bridge::frb;
use nostr_sdk::prelude::*;
use whitenoise::whitenoise::message_aggregator::ChatMessageSummary as WhitenoiseChatMessageSummary;
pub use whitenoise::{
    ChatMessage as WhitenoiseChatMessage, EmojiReaction as WhitenoiseEmojiReaction,
    MediaFile as WhitenoiseMediaFile, MessageUpdate as WhitenoiseMessageUpdate,
    MessageWithTokens as WhitenoiseMessageWithTokens, ReactionSummary as WhitenoiseReactionSummary,
    SerializableToken as WhitenoiseSerializableToken, UpdateTrigger as WhitenoiseUpdateTrigger,
    UserReaction as WhitenoiseUserReaction, Whitenoise,
};

/// Flutter-compatible message with tokens
#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct MessageWithTokens {
    pub id: String,
    pub pubkey: String,
    pub kind: u16,
    pub created_at: DateTime<Utc>,
    pub content: Option<String>,
    pub tokens: Vec<SerializableToken>,
}

/// Flutter-compatible chat message
#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct ChatMessage {
    pub id: String,
    pub pubkey: String,
    pub content: String,
    pub created_at: DateTime<Utc>,
    pub tags: Vec<String>, // Simplified tags representation for Flutter
    pub is_reply: bool,
    pub reply_to_id: Option<String>,
    pub is_deleted: bool,
    pub content_tokens: Vec<SerializableToken>,
    pub reactions: ReactionSummary,
    pub media_attachments: Vec<MediaFile>,
    pub kind: u16,
}

/// Flutter-compatible reaction summary
#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct ReactionSummary {
    pub by_emoji: Vec<EmojiReaction>,
    pub user_reactions: Vec<UserReaction>,
}

/// Flutter-compatible emoji reaction details
#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct EmojiReaction {
    pub emoji: String,
    pub count: u64,         // Using u64 for Flutter compatibility
    pub users: Vec<String>, // PublicKey converted to hex strings
}

/// Flutter-compatible user reaction
#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct UserReaction {
    pub user: String, // PublicKey converted to hex string
    pub emoji: String,
    pub created_at: DateTime<Utc>,
}

/// Flutter-compatible serializable token
#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct SerializableToken {
    pub token_type: String, // "Nostr", "Url", "Hashtag", "Text", "LineBreak", "Whitespace"
    pub content: Option<String>, // None for LineBreak and Whitespace
}

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct ChatMessageSummary {
    pub mls_group_id: String,
    pub author: String,
    pub author_display_name: Option<String>,
    pub content: String,
    pub created_at: DateTime<Utc>,
    pub media_attachment_count: u64,
}

/// What triggered a message update in the stream.
#[frb]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum UpdateTrigger {
    /// A new message was added to the group
    NewMessage,
    /// A reaction was added to this message
    ReactionAdded,
    /// A reaction was removed from this message
    ReactionRemoved,
    /// The message itself was marked as deleted
    MessageDeleted,
}

/// A real-time update for a group message.
///
/// Contains the trigger indicating what changed and the complete,
/// current state of the affected message.
#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct MessageUpdate {
    pub trigger: UpdateTrigger,
    pub message: ChatMessage,
}

/// Stream item emitted by `subscribe_to_group_messages`.
///
/// The first item is always `InitialSnapshot` containing all current messages.
/// Subsequent items are `Update` containing real-time changes.
#[frb]
#[derive(Debug, Clone)]
pub enum MessageStreamItem {
    /// Initial snapshot of all messages in the group at subscription time
    InitialSnapshot { messages: Vec<ChatMessage> },
    /// Real-time update for a single message
    Update { update: MessageUpdate },
}

// From implementations to convert from Whitenoise types to Flutter-compatible types

impl From<&WhitenoiseMessageWithTokens> for MessageWithTokens {
    fn from(message_with_tokens: &WhitenoiseMessageWithTokens) -> Self {
        // Convert tokens to Flutter-compatible representation
        let tokens = message_with_tokens
            .tokens
            .iter()
            .map(|token| token.into())
            .collect();

        Self {
            id: message_with_tokens.message.id.to_hex(),
            pubkey: message_with_tokens.message.pubkey.to_hex(),
            kind: message_with_tokens.message.kind.as_u16(),
            created_at: {
                let ts =
                    i64::try_from(message_with_tokens.message.created_at.as_u64()).unwrap_or(0);
                Utc.timestamp_opt(ts, 0)
                    .single()
                    .unwrap_or_else(|| Utc.timestamp_opt(0, 0).single().unwrap())
            },
            content: Some(message_with_tokens.message.content.clone()),
            tokens,
        }
    }
}

impl From<WhitenoiseMessageWithTokens> for MessageWithTokens {
    fn from(message_with_tokens: WhitenoiseMessageWithTokens) -> Self {
        (&message_with_tokens).into()
    }
}

impl From<&WhitenoiseSerializableToken> for SerializableToken {
    fn from(token: &WhitenoiseSerializableToken) -> Self {
        match token {
            WhitenoiseSerializableToken::Nostr(s) => Self {
                token_type: "Nostr".to_string(),
                content: Some(s.clone()),
            },
            WhitenoiseSerializableToken::Url(s) => Self {
                token_type: "Url".to_string(),
                content: Some(s.clone()),
            },
            WhitenoiseSerializableToken::Hashtag(s) => Self {
                token_type: "Hashtag".to_string(),
                content: Some(s.clone()),
            },
            WhitenoiseSerializableToken::Text(s) => Self {
                token_type: "Text".to_string(),
                content: Some(s.clone()),
            },
            WhitenoiseSerializableToken::LineBreak => Self {
                token_type: "LineBreak".to_string(),
                content: None,
            },
            WhitenoiseSerializableToken::Whitespace => Self {
                token_type: "Whitespace".to_string(),
                content: None,
            },
        }
    }
}

impl From<WhitenoiseSerializableToken> for SerializableToken {
    fn from(token: WhitenoiseSerializableToken) -> Self {
        (&token).into()
    }
}

impl From<WhitenoiseChatMessageSummary> for ChatMessageSummary {
    fn from(summary: WhitenoiseChatMessageSummary) -> Self {
        Self {
            mls_group_id: group_id_to_string(&summary.mls_group_id),
            author: summary.author.to_hex(),
            author_display_name: summary.author_display_name,
            content: summary.content,
            created_at: summary.created_at,
            media_attachment_count: summary.media_attachment_count as u64,
        }
    }
}

impl From<&WhitenoiseReactionSummary> for ReactionSummary {
    fn from(reactions: &WhitenoiseReactionSummary) -> Self {
        let by_emoji = reactions
            .by_emoji
            .iter()
            .map(|(emoji, reaction)| EmojiReaction {
                emoji: emoji.clone(),
                count: reaction.count as u64,
                users: reaction.users.iter().map(|pk| pk.to_hex()).collect(),
            })
            .collect();

        let user_reactions = reactions
            .user_reactions
            .iter()
            .map(|user_reaction| UserReaction {
                user: user_reaction.user.to_hex(),
                emoji: user_reaction.emoji.clone(),
                created_at: {
                    let ts = i64::try_from(user_reaction.created_at.as_u64()).unwrap_or(0);
                    Utc.timestamp_opt(ts, 0)
                        .single()
                        .unwrap_or_else(|| Utc.timestamp_opt(0, 0).single().unwrap())
                },
            })
            .collect();

        Self {
            by_emoji,
            user_reactions,
        }
    }
}

impl From<WhitenoiseReactionSummary> for ReactionSummary {
    fn from(reactions: WhitenoiseReactionSummary) -> Self {
        (&reactions).into()
    }
}

impl From<&WhitenoiseChatMessage> for ChatMessage {
    fn from(chat_message: &WhitenoiseChatMessage) -> Self {
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
            .map(|token| token.into())
            .collect();

        // Convert reactions to proper Flutter-compatible struct
        let reactions = (&chat_message.reactions).into();

        Self {
            id: chat_message.id.clone(),
            pubkey: chat_message.author.to_hex(),
            content: chat_message.content.clone(),
            created_at: {
                let ts = i64::try_from(chat_message.created_at.as_u64()).unwrap_or(0);
                Utc.timestamp_opt(ts, 0)
                    .single()
                    .unwrap_or_else(|| Utc.timestamp_opt(0, 0).single().unwrap())
            },
            tags,
            is_reply: chat_message.is_reply,
            reply_to_id: chat_message.reply_to_id.clone(),
            is_deleted: chat_message.is_deleted,
            content_tokens,
            reactions,
            media_attachments: chat_message
                .media_attachments
                .clone()
                .into_iter()
                .map(|media_file| media_file.into())
                .collect(),
            kind: chat_message.kind,
        }
    }
}

impl From<WhitenoiseChatMessage> for ChatMessage {
    fn from(chat_message: WhitenoiseChatMessage) -> Self {
        (&chat_message).into()
    }
}

impl From<WhitenoiseUpdateTrigger> for UpdateTrigger {
    fn from(trigger: WhitenoiseUpdateTrigger) -> Self {
        match trigger {
            WhitenoiseUpdateTrigger::NewMessage => Self::NewMessage,
            WhitenoiseUpdateTrigger::ReactionAdded => Self::ReactionAdded,
            WhitenoiseUpdateTrigger::ReactionRemoved => Self::ReactionRemoved,
            WhitenoiseUpdateTrigger::MessageDeleted => Self::MessageDeleted,
        }
    }
}

impl From<&WhitenoiseMessageUpdate> for MessageUpdate {
    fn from(update: &WhitenoiseMessageUpdate) -> Self {
        Self {
            trigger: update.trigger.clone().into(),
            message: (&update.message).into(),
        }
    }
}

impl From<WhitenoiseMessageUpdate> for MessageUpdate {
    fn from(update: WhitenoiseMessageUpdate) -> Self {
        (&update).into()
    }
}

#[frb]
pub async fn send_message_to_group(
    pubkey: String,
    group_id: String,
    message: String,
    kind: u16,
    tags: Option<Vec<Tag>>,
) -> Result<MessageWithTokens, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let group_id = group_id_from_string(&group_id)?;
    let message_with_tokens = whitenoise
        .send_message_to_group(&account, &group_id, message, kind, tags)
        .await?;
    Ok((&message_with_tokens).into())
}

#[frb]
pub async fn fetch_aggregated_messages_for_group(
    pubkey: String,
    group_id: String,
) -> Result<Vec<ChatMessage>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let group_id = group_id_from_string(&group_id)?;
    let messages = whitenoise
        .fetch_aggregated_messages_for_group(&pubkey, &group_id)
        .await?;
    Ok(messages.into_iter().map(|m| m.into()).collect())
}

/// Subscribe to real-time message updates for a group.
///
/// The stream first emits an `InitialSnapshot` containing all current messages,
/// then emits `Update` items as messages are added, reacted to, or deleted.
///
/// The initial snapshot is race-condition free: any updates that arrive between
/// subscribing and fetching are merged into the snapshot.
#[frb]
pub async fn subscribe_to_group_messages(
    group_id: String,
    sink: StreamSink<MessageStreamItem>,
) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let group_id = group_id_from_string(&group_id)?;

    let subscription = whitenoise.subscribe_to_group_messages(&group_id).await?;

    // Emit initial snapshot first
    let initial_messages: Vec<ChatMessage> = subscription
        .initial_messages
        .into_iter()
        .map(|m| m.into())
        .collect();

    if sink
        .add(MessageStreamItem::InitialSnapshot {
            messages: initial_messages,
        })
        .is_err()
    {
        return Ok(()); // Sink closed, exit gracefully
    }

    // Stream real-time updates
    let mut rx = subscription.updates;
    loop {
        match rx.recv().await {
            Ok(update) => {
                let item = MessageStreamItem::Update {
                    update: update.into(),
                };
                if sink.add(item).is_err() {
                    break; // Sink closed
                }
            }
            Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => {
                // Slow consumer missed some updates - safe to continue since
                // each update contains the complete message state
                continue;
            }
            Err(tokio::sync::broadcast::error::RecvError::Closed) => {
                break; // Channel closed
            }
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_update_trigger_conversion_new_message() {
        let trigger: UpdateTrigger = WhitenoiseUpdateTrigger::NewMessage.into();
        assert_eq!(trigger, UpdateTrigger::NewMessage);
    }

    #[test]
    fn test_update_trigger_conversion_reaction_added() {
        let trigger: UpdateTrigger = WhitenoiseUpdateTrigger::ReactionAdded.into();
        assert_eq!(trigger, UpdateTrigger::ReactionAdded);
    }

    #[test]
    fn test_update_trigger_conversion_reaction_removed() {
        let trigger: UpdateTrigger = WhitenoiseUpdateTrigger::ReactionRemoved.into();
        assert_eq!(trigger, UpdateTrigger::ReactionRemoved);
    }

    #[test]
    fn test_update_trigger_conversion_message_deleted() {
        let trigger: UpdateTrigger = WhitenoiseUpdateTrigger::MessageDeleted.into();
        assert_eq!(trigger, UpdateTrigger::MessageDeleted);
    }
}
