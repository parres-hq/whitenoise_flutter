use chrono::{DateTime, Utc};
use flutter_rust_bridge::frb;
use url::Url;
use whitenoise::{Account as WhitenoiseAccount, Event, ImageType, Metadata, PublicKey, Relay, RelayType, RelayUrl, User, Whitenoise, WhitenoiseError};
use crate::api::metadata::FlutterMetadata;

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

#[frb]
pub async fn get_accounts() -> Result<Vec<Account>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let accounts = whitenoise.all_accounts().await?;
    Ok(accounts.into_iter().map(|a| a.into()).collect())
}

#[frb]
pub async fn get_account(pubkey: String) -> Result<Account, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    Ok(account.into())
}

#[frb]
pub async fn create_identity() -> Result<Account, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.create_identity().await?;
    Ok(account.into())
}

#[frb]
pub async fn login(nsec_or_hex_privkey: String) -> Result<Account, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.login(nsec_or_hex_privkey).await?;
    Ok(account.into())
}

#[frb]
pub async fn logout(pubkey: String) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    whitenoise.logout(&pubkey).await
}

#[frb]
pub async fn export_account_nsec(pubkey: String) -> Result<String, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    whitenoise.export_account_nsec(&account).await
}

#[frb]
pub async fn account_metadata(pubkey: String) -> Result<FlutterMetadata, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let metadata = account.metadata(whitenoise).await?;
    Ok(metadata.into())
}

#[frb]
pub async fn update_account_metadata(
    pubkey: String,
    metadata: &Metadata,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    account.update_metadata(&metadata, whitenoise).await
}

#[frb]
pub async fn upload_account_profile_picture(
    pubkey: String,
    server_url: String,
    file_path: String,
    image_type: String,
) -> Result<String, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let image_type = ImageType::try_from(image_type)?;

    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let server =
        Url::parse(&server_url).map_err(|e| WhitenoiseError::from(std::io::Error::other(e)))?;

    account
        .upload_profile_picture(&file_path, image_type, server, &whitenoise)
        .await
}

#[frb]
pub async fn account_relays(
    pubkey: String,
    relay_type: RelayType,
) -> Result<Vec<Relay>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let relays = account.relays(relay_type, whitenoise).await?;
    Ok(relays.into())
}

#[frb]
pub async fn add_account_relay(
    pubkey: String,
    url: String,
    relay_type: RelayType,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let relay_url = RelayUrl::parse(&url)?;
    let relay = whitenoise.find_or_create_relay_by_url(&relay_url).await?;
    account.add_relay(&relay, relay_type, whitenoise).await
}

#[frb]
pub async fn remove_account_relay(
    pubkey: String,
    url: String,
    relay_type: RelayType,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let relay_url = RelayUrl::parse(&url)?;
    let relay = whitenoise.find_or_create_relay_by_url(&relay_url).await?;
    account.remove_relay(&relay, relay_type, whitenoise).await
}

#[frb]
pub async fn account_key_package(pubkey: String) -> Result<Option<Event>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let user = whitenoise.find_user_by_pubkey(&pubkey).await?;
    user.key_package_event(whitenoise).await
}

#[frb]
pub async fn account_follows(pubkey: String) -> Result<Vec<User>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let follows = whitenoise.follows(&account).await?;
    Ok(follows.into())
}

#[frb]
pub async fn follow_user(
    account_pubkey: String,
    user_to_follow_pubkey: String,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&account_pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let user_to_follow_pubkey = PublicKey::from_hex(&user_to_follow_pubkey)?;
    whitenoise
        .follow_user(&account, &user_to_follow_pubkey)
        .await
}

#[frb]
pub async fn unfollow_user(
    account_pubkey: String,
    user_to_unfollow_pubkey: String,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&account_pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let user_to_unfollow_pubkey = PublicKey::from_hex(&user_to_unfollow_pubkey)?;
    whitenoise
        .unfollow_user(&account, &user_to_unfollow_pubkey)
        .await
}
