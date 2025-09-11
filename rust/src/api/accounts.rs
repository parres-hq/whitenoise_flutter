use crate::api::{error::ApiError, metadata::FlutterMetadata, relays::Relay, users::User};
use chrono::{DateTime, TimeZone, Utc};
use flutter_rust_bridge::frb;
use nostr_sdk::prelude::*;
use whitenoise::{Account as WhitenoiseAccount, ImageType, RelayType, Whitenoise};

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct Account {
    pub pubkey: String,
    pub last_synced_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<WhitenoiseAccount> for Account {
    fn from(account: WhitenoiseAccount) -> Self {
        Self {
            pubkey: account.pubkey.to_hex(),
            last_synced_at: account.last_synced_at,
            created_at: account.created_at,
            updated_at: account.updated_at,
        }
    }
}

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct FlutterEvent {
    pub id: String,
    pub pubkey: String,
    pub created_at: DateTime<Utc>,
    pub kind: u16,
    pub tags: Vec<String>,
    pub content: String,
}

impl From<Event> for FlutterEvent {
    fn from(event: Event) -> Self {
        Self {
            id: event.id.to_hex(),
            pubkey: event.pubkey.to_hex(),
            created_at: {
                let ts = i64::try_from(event.created_at.as_u64()).unwrap_or(0);
                Utc.timestamp_opt(ts, 0)
                    .single()
                    .unwrap_or_else(|| Utc.timestamp_opt(0, 0).single().unwrap())
            },
            kind: event.kind.as_u16(),
            tags: event.tags.iter().map(|tag| format!("{:?}", tag)).collect(),
            content: event.content,
        }
    }
}

#[frb]
pub async fn get_accounts() -> Result<Vec<Account>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let accounts = whitenoise.all_accounts().await?;
    Ok(accounts.into_iter().map(|a| a.into()).collect())
}

#[frb]
pub async fn get_account(pubkey: String) -> Result<Account, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    Ok(account.into())
}

#[frb]
pub async fn create_identity() -> Result<Account, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.create_identity().await?;
    Ok(account.into())
}

#[frb]
pub async fn login(nsec_or_hex_privkey: String) -> Result<Account, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.login(nsec_or_hex_privkey).await?;
    Ok(account.into())
}

#[frb]
pub async fn logout(pubkey: String) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    whitenoise.logout(&pubkey).await.map_err(ApiError::from)
}

#[frb]
pub async fn export_account_nsec(pubkey: String) -> Result<String, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    whitenoise
        .export_account_nsec(&account)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn account_metadata(pubkey: String) -> Result<FlutterMetadata, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let metadata = account.metadata(whitenoise).await?;
    Ok(metadata.into())
}

#[frb]
pub async fn update_account_metadata(
    pubkey: String,
    metadata: &FlutterMetadata,
) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    account
        .update_metadata(&metadata.into(), whitenoise)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn upload_account_profile_picture(
    pubkey: String,
    server_url: String,
    file_path: String,
    image_type: String,
) -> Result<String, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let image_type = ImageType::try_from(image_type)?;

    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let server = Url::parse(&server_url)?;

    account
        .upload_profile_picture(&file_path, image_type, server, &whitenoise)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn account_relays(pubkey: String, relay_type: RelayType) -> Result<Vec<Relay>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let relays = account.relays(relay_type, whitenoise).await?;
    Ok(relays.into_iter().map(|r| r.into()).collect())
}

#[frb]
pub async fn add_account_relay(
    pubkey: String,
    url: String,
    relay_type: RelayType,
) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let relay_url = RelayUrl::parse(&url)?;
    let relay = whitenoise.find_or_create_relay_by_url(&relay_url).await?;
    account
        .add_relay(&relay, relay_type, whitenoise)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn remove_account_relay(
    pubkey: String,
    url: String,
    relay_type: RelayType,
) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let relay_url = RelayUrl::parse(&url)?;
    let relay = whitenoise.find_or_create_relay_by_url(&relay_url).await?;
    account
        .remove_relay(&relay, relay_type, whitenoise)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn account_key_package(pubkey: String) -> Result<Option<FlutterEvent>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let user = whitenoise.find_user_by_pubkey(&pubkey).await?;
    let event = user.key_package_event(whitenoise).await?;
    Ok(event.map(|e| e.into()))
}

#[frb]
pub async fn account_key_packages(account_pubkey: String) -> Result<Vec<FlutterEvent>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let key_packages = whitenoise
        .find_all_key_packages_for_account(&account)
        .await?;
    Ok(key_packages.into_iter().map(|e| e.into()).collect())
}

#[frb]
pub async fn publish_account_key_package(account_pubkey: String) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    whitenoise
        .publish_key_package_for_account(&account)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn delete_account_key_package(
    account_pubkey: String,
    key_package_id: String,
) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let key_package_id = EventId::parse(&key_package_id)?;
    whitenoise
        .delete_key_package_for_account(&account, &key_package_id, true)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn delete_account_key_packages(account_pubkey: String) -> Result<usize, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let deleted_count = whitenoise
        .delete_all_key_packages_for_account(&account, true)
        .await?;
    Ok(deleted_count)
}

#[frb]
pub async fn account_follows(pubkey: String) -> Result<Vec<User>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let follows = whitenoise.follows(&account).await?;
    Ok(follows.into_iter().map(|u| u.into()).collect())
}

#[frb]
pub async fn follow_user(
    account_pubkey: String,
    user_to_follow_pubkey: String,
) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let user_to_follow_pubkey = PublicKey::parse(&user_to_follow_pubkey)?;
    whitenoise
        .follow_user(&account, &user_to_follow_pubkey)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn unfollow_user(
    account_pubkey: String,
    user_to_unfollow_pubkey: String,
) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let user_to_unfollow_pubkey = PublicKey::parse(&user_to_unfollow_pubkey)?;
    whitenoise
        .unfollow_user(&account, &user_to_unfollow_pubkey)
        .await
        .map_err(ApiError::from)
}
