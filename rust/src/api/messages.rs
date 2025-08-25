use crate::api::{error::ApiResult, utils::group_id_from_string};
use chrono::{DateTime, Utc};
use flutter_rust_bridge::frb;
use nostr_sdk::prelude::*;
pub use whitenoise::{
    ChatMessage as WhitenoiseChatMessage, EmojiReaction as WhitenoiseEmojiReaction,
    MessageWithTokens as WhitenoiseMessageWithTokens, ReactionSummary as WhitenoiseReactionSummary,
    SerializableToken as WhitenoiseSerializableToken, UserReaction as WhitenoiseUserReaction,
    Whitenoise,
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
            created_at: DateTime::from_timestamp(
                message_with_tokens.message.created_at.as_u64() as i64,
                0,
            )
            .unwrap_or_else(|| DateTime::from_timestamp(0, 0).unwrap()),
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
                created_at: DateTime::from_timestamp(user_reaction.created_at.as_u64() as i64, 0)
                    .unwrap_or_else(|| DateTime::from_timestamp(0, 0).unwrap()),
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
            created_at: DateTime::from_timestamp(chat_message.created_at.as_u64() as i64, 0)
                .unwrap_or_else(|| DateTime::from_timestamp(0, 0).unwrap()),
            tags,
            is_reply: chat_message.is_reply,
            reply_to_id: chat_message.reply_to_id.clone(),
            is_deleted: chat_message.is_deleted,
            content_tokens,
            reactions,
            kind: chat_message.kind,
        }
    }
}

impl From<WhitenoiseChatMessage> for ChatMessage {
    fn from(chat_message: WhitenoiseChatMessage) -> Self {
        (&chat_message).into()
    }
}

#[frb]
pub async fn send_message_to_group(
    pubkey: String,
    group_id: String,
    message: String,
    kind: u16,
    tags: Option<Vec<Tag>>,
) -> ApiResult<MessageWithTokens> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
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
) -> ApiResult<Vec<ChatMessage>> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let group_id = group_id_from_string(&group_id)?;
    let messages = whitenoise
        .fetch_aggregated_messages_for_group(&pubkey, &group_id)
        .await?;
    Ok(messages.into_iter().map(|m| m.into()).collect())
}
