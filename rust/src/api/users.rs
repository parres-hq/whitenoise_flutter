use crate::api::relays::Relay;
use crate::api::{metadata::FlutterMetadata, ApiError, ApiResult};
use chrono::{DateTime, Utc};
use flutter_rust_bridge::frb;
use nostr_sdk::prelude::*;
use whitenoise::{RelayType, User as WhitenoiseUser, Whitenoise};

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
pub async fn get_user(pubkey: String) -> ApiResult<User> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let user = whitenoise
        .find_user_by_pubkey(&pubkey)
        .await
        .map_err(ApiError::from)?;
    Ok(user.into())
}

#[frb]
pub async fn user_metadata(pubkey: String) -> ApiResult<FlutterMetadata> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let user = whitenoise.find_user_by_pubkey(&pubkey).await?;
    Ok(user.metadata.into())
}

#[frb]
pub async fn user_relays(pubkey: String, relay_type: RelayType) -> ApiResult<Vec<Relay>> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let user = whitenoise.find_user_by_pubkey(&pubkey).await?;
    let relays = user.relays_by_type(relay_type, &whitenoise).await?;
    Ok(relays.into_iter().map(|r| r.into()).collect())
}
