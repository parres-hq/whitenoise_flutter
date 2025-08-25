use flutter_rust_bridge::frb;
use thiserror::Error;

/// Type alias for Results that use ApiError as the error type
/// This makes function signatures cleaner throughout the API layer
pub type ApiResult<T> = Result<T, ApiError>;

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

impl From<nostr_sdk::util::hex::Error> for ApiError {
    fn from(error: nostr_sdk::util::hex::Error) -> Self {
        Self::NostrHex {
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
    pub fn error_type(&self) -> &'static str {
        match self {
            ApiError::Whitenoise { .. } => "Whitenoise",
            ApiError::InvalidKey { .. } => "InvalidKey",
            ApiError::NostrUrl { .. } => "NostrUrl",
            ApiError::NostrTag { .. } => "NostrTag",
            ApiError::NostrEvent { .. } => "NostrEvent",
            ApiError::NostrParse { .. } => "NostrParse",
            ApiError::NostrHex { .. } => "NostrHex",
            ApiError::Other { .. } => "Other",
        }
    }

    /// Get the error message
    pub fn message(&self) -> &str {
        match self {
            ApiError::Whitenoise { message } => message,
            ApiError::InvalidKey { message } => message,
            ApiError::NostrUrl { message } => message,
            ApiError::NostrTag { message } => message,
            ApiError::NostrEvent { message } => message,
            ApiError::NostrParse { message } => message,
            ApiError::NostrHex { message } => message,
            ApiError::Other { message } => message,
        }
    }
}
