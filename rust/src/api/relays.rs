use crate::api::error::ApiError;
use chrono::{DateTime, Utc};
use flutter_rust_bridge::frb;
use nostr_sdk::prelude::*;
use whitenoise::{Relay as WhitenoiseRelay, RelayType, Whitenoise};

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct Relay {
    pub url: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<WhitenoiseRelay> for Relay {
    fn from(relay: WhitenoiseRelay) -> Self {
        Self {
            url: relay.url.to_string(),
            created_at: relay.created_at,
            updated_at: relay.updated_at,
        }
    }
}

#[frb]
pub fn relay_type_nip65() -> RelayType {
    RelayType::Nip65
}

#[frb]
pub fn relay_type_inbox() -> RelayType {
    RelayType::Inbox
}

#[frb]
pub fn relay_type_key_package() -> RelayType {
    RelayType::KeyPackage
}

#[frb]
pub async fn get_account_relay_statuses(pubkey: String) -> Result<Vec<(String, String)>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let statuses = whitenoise.get_account_relay_statuses(&account).await?;
    let converted_statuses = statuses
        .into_iter()
        .map(|(url, status)| (url.to_string(), status.to_string()))
        .collect();
    Ok(converted_statuses)
}

/// Ensures all subscriptions (global and all accounts) are operational.
///
/// This method is designed for periodic background tasks that need to ensure
/// the entire subscription system is functioning. It checks and refreshes
/// global subscriptions first, then iterates through all accounts.
///
/// Uses a best-effort strategy: if one subscription check fails, logs the error
/// and continues with the remaining checks. This maximizes the number of working
/// subscriptions even when some fail due to transient network issues.
///
/// # Error Handling
///
/// - **Subscription errors**: Logged and ignored, processing continues
/// - **Database errors**: Propagated immediately (catastrophic failure)
///
/// # Returns
///
/// - `Ok(())`: Completed all checks (some may have failed, check logs)
/// - `Err(_)`: Only on catastrophic failures (e.g., database connection lost)
#[frb]
pub async fn ensure_all_subscriptions() -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise
        .ensure_all_subscriptions()
        .await
        .map_err(ApiError::from)
}
