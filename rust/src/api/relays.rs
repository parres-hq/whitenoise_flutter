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
pub async fn fetch_relay_status(pubkey: String) -> Result<Vec<(String, String)>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let statuses = whitenoise.fetch_relay_status(&account).await?;
    let converted_statuses = statuses
        .into_iter()
        .map(|(url, status)| (url.to_string(), status.to_string()))
        .collect();
    Ok(converted_statuses)
}
