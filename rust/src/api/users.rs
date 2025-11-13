use crate::api::relays::Relay;
use crate::api::{ApiError, metadata::FlutterMetadata};
use chrono::{DateTime, Utc};
use flutter_rust_bridge::frb;
use nostr_sdk::prelude::*;
use whitenoise::{RelayType, User as WhitenoiseUser, UserSyncMode, Whitenoise};

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct User {
    pub pubkey: String,
    pub metadata: FlutterMetadata,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<WhitenoiseUser> for User {
    fn from(user: WhitenoiseUser) -> Self {
        Self {
            pubkey: user.pubkey.to_hex(),
            metadata: user.metadata.into(),
            created_at: user.created_at,
            updated_at: user.updated_at,
        }
    }
}

#[frb]
pub async fn get_user(pubkey: String, blocking_data_sync: bool) -> Result<User, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let sync_mode = if blocking_data_sync {
        UserSyncMode::Blocking
    } else {
        UserSyncMode::Background
    };
    let user = whitenoise
        .find_or_create_user_by_pubkey(&pubkey, sync_mode)
        .await
        .map_err(ApiError::from)?;
    Ok(user.into())
}

#[frb]
pub async fn user_metadata(
    pubkey: String,
    blocking_data_sync: bool,
) -> Result<FlutterMetadata, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let sync_mode = if blocking_data_sync {
        UserSyncMode::Blocking
    } else {
        UserSyncMode::Background
    };
    let user = whitenoise
        .find_or_create_user_by_pubkey(&pubkey, sync_mode)
        .await?;
    Ok(user.metadata.into())
}

#[frb]
pub async fn user_relays(
    pubkey: String,
    relay_type: RelayType,
    blocking_data_sync: bool,
) -> Result<Vec<Relay>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let sync_mode = if blocking_data_sync {
        UserSyncMode::Blocking
    } else {
        UserSyncMode::Background
    };
    let user = whitenoise
        .find_or_create_user_by_pubkey(&pubkey, sync_mode)
        .await?;
    let relays = user.relays_by_type(relay_type, &whitenoise).await?;
    Ok(relays.into_iter().map(|r| r.into()).collect())
}

#[frb]
pub async fn user_has_key_package(
    pubkey: String,
    blocking_data_sync: bool,
) -> Result<bool, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let sync_mode = if blocking_data_sync {
        UserSyncMode::Blocking
    } else {
        UserSyncMode::Background
    };
    let user = whitenoise
        .find_or_create_user_by_pubkey(&pubkey, sync_mode)
        .await?;
    Ok(user.key_package_event(whitenoise).await?.is_some())
}
