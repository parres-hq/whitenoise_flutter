use crate::api::utils::{
    convert_metadata_data_to_metadata, convert_metadata_to_data, MetadataData,
};
use flutter_rust_bridge::frb;
pub use whitenoise::{
    Account, AccountSettings, OnboardingState, PublicKey, Whitenoise, WhitenoiseError,
};

#[derive(Debug, Clone)]
pub struct AccountData {
    pub pubkey: String,
    pub settings: AccountSettings,
    pub onboarding: OnboardingState,
    pub last_synced: u64,
}

// Mirror structs for simple types that can be used directly
#[frb(mirror(AccountSettings))]
#[derive(Debug, Clone)]
pub struct _AccountSettings {
    pub dark_theme: bool,
    pub dev_mode: bool,
    pub lockdown_mode: bool,
}

#[frb(mirror(OnboardingState))]
#[derive(Debug, Clone)]
pub struct _OnboardingState {
    pub inbox_relays: bool,
    pub key_package_relays: bool,
    pub key_package_published: bool,
}

/// Converts a core `Account` object to a Flutter-compatible `AccountData` structure.
///
/// This function bridges the gap between the core Whitenoise library's Account type
/// and the Flutter-compatible AccountData structure, converting complex types like
/// timestamps and public keys to their string representations.
///
/// # Parameters
/// * `account` - Reference to a core Account object
///
/// # Returns
/// An AccountData struct with all fields converted for Flutter compatibility
#[frb]
pub fn convert_account_to_data(account: &Account) -> AccountData {
    AccountData {
        pubkey: account.pubkey.to_hex(),
        settings: account.settings.clone(),
        onboarding: account.onboarding.clone(),
        last_synced: account.last_synced.as_u64(),
    }
}

/// Fetch all accounts that are stored on the whitenoise instance (these are "logged in" accounts)
#[frb]
pub async fn fetch_accounts() -> Result<Vec<AccountData>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let accounts = whitenoise.fetch_accounts().await?;
    Ok(accounts.values().map(convert_account_to_data).collect())
}

/// Fetch an account by its public key
#[frb]
pub async fn fetch_account(pubkey: &PublicKey) -> Result<AccountData, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    Ok(convert_account_to_data(&account))
}

/// Create a new account and get it ready for MLS messaging
#[frb]
pub async fn create_identity() -> Result<Account, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.create_identity().await
}

/// Login to an account by its private key (nsec or hex)
#[frb]
pub async fn login(nsec_or_hex_privkey: String) -> Result<Account, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.login(nsec_or_hex_privkey).await
}

/// Logout of an account by its public key
#[frb]
pub async fn logout(pubkey: &PublicKey) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.logout(pubkey).await
}

/// Export an account's private key (nsec)
#[frb]
pub async fn export_account_nsec(pubkey: &PublicKey) -> Result<String, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.export_account_nsec(&account).await
}

/// Export an account's public key (npub)
#[frb]
pub async fn export_account_npub(pubkey: &PublicKey) -> Result<String, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.export_account_npub(&account).await
}

/// Fetch an account's metadata by its public key
#[frb]
pub async fn fetch_metadata(pubkey: PublicKey) -> Result<Option<MetadataData>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let metadata = whitenoise.fetch_metadata(pubkey).await?;
    Ok(metadata.map(|m| convert_metadata_to_data(&m)))
}

/// Update an account's metadata
#[frb]
pub async fn update_metadata(
    metadata: &MetadataData,
    pubkey: &PublicKey,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    // Convert MetadataData back to Metadata for the whitenoise API
    let metadata_to_save = convert_metadata_data_to_metadata(metadata);
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise
        .update_metadata(&metadata_to_save, &account)
        .await
}

/// Fetch an account's onboarding state by its public key
#[frb]
pub async fn fetch_onboarding_state(pubkey: PublicKey) -> Result<OnboardingState, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.fetch_onboarding_state(pubkey).await
}
