use crate::api::utils::group_id_from_string;
use flutter_rust_bridge::frb;
pub use whitenoise::{
    ChatMessage, EmojiReaction, GroupId, MessageWithTokens, PublicKey, ReactionSummary,
    SerializableToken, Tag, UserReaction, Whitenoise, WhitenoiseError,
};

#[derive(Debug, Clone)]
pub struct _MessageWithTokens {
    pub id: String,
    pub pubkey: String,
    pub kind: u16,
    pub created_at: u64,
    pub content: Option<String>,
    pub tokens: Vec<String>, // Simplified tokens representation
}

#[derive(Debug, Clone)]
pub struct _ChatMessage {
    pub id: String,
    pub pubkey: String,
    pub content: String,
    pub created_at: u64,
    pub tags: Vec<String>, // Simplified tags representation for Flutter
    pub is_reply: bool,
    pub reply_to_id: Option<String>,
    pub is_deleted: bool,
    pub content_tokens: Vec<_SerializableToken>,
    pub reactions: _ReactionSummary,
    pub kind: u16,
}

/// Flutter-compatible reaction summary
#[derive(Debug, Clone)]
pub struct _ReactionSummary {
    pub by_emoji: Vec<_EmojiReaction>,
    pub user_reactions: Vec<_UserReaction>,
}

/// Flutter-compatible emoji reaction details
#[derive(Debug, Clone)]
pub struct _EmojiReaction {
    pub emoji: String,
    pub count: u64,         // Using u64 for Flutter compatibility
    pub users: Vec<String>, // PublicKey converted to hex strings
}

/// Flutter-compatible user reaction
#[derive(Debug, Clone)]
pub struct _UserReaction {
    pub user: String, // PublicKey converted to hex string
    pub emoji: String,
    pub created_at: u64, // Timestamp converted to u64
}

/// Flutter-compatible serializable token
#[derive(Debug, Clone)]
pub struct _SerializableToken {
    pub token_type: String, // "Nostr", "Url", "Hashtag", "Text", "LineBreak", "Whitespace"
    pub content: Option<String>, // None for LineBreak and Whitespace
}

// From implementations to replace convert_ functions

impl From<&MessageWithTokens> for _MessageWithTokens {
    fn from(message_with_tokens: &MessageWithTokens) -> Self {
        // Convert tokens to simplified string representation
        let tokens = message_with_tokens
            .tokens
            .iter()
            .map(|token| format!("{token:?}"))
            .collect();

        Self {
            id: message_with_tokens.message.id.to_hex(),
            pubkey: message_with_tokens.message.pubkey.to_hex(),
            kind: message_with_tokens.message.kind.as_u16(),
            created_at: message_with_tokens.message.created_at.as_u64(),
            content: Some(message_with_tokens.message.content.clone()),
            tokens,
        }
    }
}

impl From<MessageWithTokens> for _MessageWithTokens {
    fn from(message_with_tokens: MessageWithTokens) -> Self {
        (&message_with_tokens).into()
    }
}

impl From<&SerializableToken> for _SerializableToken {
    fn from(token: &SerializableToken) -> Self {
        match token {
            SerializableToken::Nostr(s) => Self {
                token_type: "Nostr".to_string(),
                content: Some(s.clone()),
            },
            SerializableToken::Url(s) => Self {
                token_type: "Url".to_string(),
                content: Some(s.clone()),
            },
            SerializableToken::Hashtag(s) => Self {
                token_type: "Hashtag".to_string(),
                content: Some(s.clone()),
            },
            SerializableToken::Text(s) => Self {
                token_type: "Text".to_string(),
                content: Some(s.clone()),
            },
            SerializableToken::LineBreak => Self {
                token_type: "LineBreak".to_string(),
                content: None,
            },
            SerializableToken::Whitespace => Self {
                token_type: "Whitespace".to_string(),
                content: None,
            },
        }
    }
}

impl From<SerializableToken> for _SerializableToken {
    fn from(token: SerializableToken) -> Self {
        (&token).into()
    }
}

impl From<&ReactionSummary> for _ReactionSummary {
    fn from(reactions: &ReactionSummary) -> Self {
        let by_emoji = reactions
            .by_emoji
            .iter()
            .map(|(emoji, reaction)| _EmojiReaction {
                emoji: emoji.clone(),
                count: reaction.count as u64,
                users: reaction.users.iter().map(|pk| pk.to_hex()).collect(),
            })
            .collect();

        let user_reactions = reactions
            .user_reactions
            .iter()
            .map(|user_reaction| _UserReaction {
                user: user_reaction.user.to_hex(),
                emoji: user_reaction.emoji.clone(),
                created_at: user_reaction.created_at.as_u64(),
            })
            .collect();

        Self {
            by_emoji,
            user_reactions,
        }
    }
}

impl From<ReactionSummary> for _ReactionSummary {
    fn from(reactions: ReactionSummary) -> Self {
        (&reactions).into()
    }
}

impl From<&ChatMessage> for _ChatMessage {
    fn from(chat_message: &ChatMessage) -> Self {
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
}

impl From<ChatMessage> for _ChatMessage {
    fn from(chat_message: ChatMessage) -> Self {
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
) -> Result<_MessageWithTokens, WhitenoiseError> {
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
) -> Result<Vec<_ChatMessage>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let group_id = group_id_from_string(&group_id)?;
    let messages = whitenoise
        .fetch_aggregated_messages_for_group(&pubkey, &group_id)
        .await?;
    Ok(messages.into_iter().map(|m| m.into()).collect())
}
