use flutter_rust_bridge::frb;
use thiserror::Error;

/// Comprehensive API error type using thiserror for better error handling
/// This enum covers all possible error scenarios in the API layer
#[frb(non_opaque)]
#[derive(Error, Debug, Clone)]
pub enum ApiError {
    /// Core whitenoise library errors
    #[error("Whitenoise error: {message}")]
    Whitenoise { message: String },

    #[error("Nostr key error: {message}")]
    InvalidKey { message: String },

    #[error("Nostr url error: {message}")]
    NostrUrl { message: String },

    #[error("Nostr tag error: {message}")]
    NostrTag { message: String },

    #[error("Nostr event error: {message}")]
    NostrEvent { message: String },

    #[error("Nostr parse error: {message}")]
    NostrParse { message: String },

    #[error("Nostr hex error: {message}")]
    NostrHex { message: String },

    #[error("Other error: {message}")]
    Other { message: String },
}

// Implement From traits for common error types
impl From<whitenoise::WhitenoiseError> for ApiError {
    fn from(error: whitenoise::WhitenoiseError) -> Self {
        Self::Whitenoise {
            message: error.to_string(),
        }
    }
}

impl From<nostr_sdk::key::Error> for ApiError {
    fn from(error: nostr_sdk::key::Error) -> Self {
        Self::InvalidKey {
            message: error.to_string(),
        }
    }
}

impl From<nostr_sdk::types::url::Error> for ApiError {
    fn from(error: nostr_sdk::types::url::Error) -> Self {
        Self::NostrUrl {
            message: error.to_string(),
        }
    }
}

impl From<nostr_sdk::event::tag::Error> for ApiError {
    fn from(error: nostr_sdk::event::tag::Error) -> Self {
        Self::NostrTag {
            message: error.to_string(),
        }
    }
}

impl From<nostr_sdk::event::Error> for ApiError {
    fn from(error: nostr_sdk::event::Error) -> Self {
        Self::NostrEvent {
            message: error.to_string(),
        }
    }
}

impl From<nostr_sdk::types::ParseError> for ApiError {
    fn from(error: nostr_sdk::types::ParseError) -> Self {
        Self::NostrParse {
            message: error.to_string(),
        }
    }
}

impl From<hex::FromHexError> for ApiError {
    fn from(error: hex::FromHexError) -> Self {
        Self::NostrHex {
            message: error.to_string(),
        }
    }
}

impl From<anyhow::Error> for ApiError {
    fn from(error: anyhow::Error) -> Self {
        Self::Other {
            message: error.to_string(),
        }
    }
}

impl ApiError {
    /// Get a user-friendly error type name
    pub fn error_type(&self) -> String {
        match self {
            ApiError::Whitenoise { .. } => "Whitenoise".to_string(),
            ApiError::InvalidKey { .. } => "InvalidKey".to_string(),
            ApiError::NostrUrl { .. } => "NostrUrl".to_string(),
            ApiError::NostrTag { .. } => "NostrTag".to_string(),
            ApiError::NostrEvent { .. } => "NostrEvent".to_string(),
            ApiError::NostrParse { .. } => "NostrParse".to_string(),
            ApiError::NostrHex { .. } => "NostrHex".to_string(),
            ApiError::Other { .. } => "Other".to_string(),
        }
    }

    /// Get the error message as a string
    pub fn message_text(&self) -> String {
        match self {
            ApiError::Whitenoise { message } => message.clone(),
            ApiError::InvalidKey { message } => message.clone(),
            ApiError::NostrUrl { message } => message.clone(),
            ApiError::NostrTag { message } => message.clone(),
            ApiError::NostrEvent { message } => message.clone(),
            ApiError::NostrParse { message } => message.clone(),
            ApiError::NostrHex { message } => message.clone(),
            ApiError::Other { message } => message.clone(),
        }
    }
}
