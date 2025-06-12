// pub mod accounts;

// Re-export everything from the whitenoise crate
use std::collections::HashMap;
use std::path::Path;
pub use whitenoise::{
    Account, AccountSettings, Event, Metadata, OnboardingState, PublicKey, RelayType, RelayUrl,
    Whitenoise, WhitenoiseConfig, WhitenoiseError,
};

use flutter_rust_bridge::frb;

// Flutter-compatible wrapper structs
#[derive(Debug, Clone)]
pub struct WhitenoiseData {
    pub config: WhitenoiseConfigData,
    pub accounts: HashMap<String, AccountData>,
    pub active_account: Option<String>,
}

#[derive(Debug, Clone)]
pub struct WhitenoiseConfigData {
    pub data_dir: String,
    pub logs_dir: String,
}

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

// Conversion functions
pub fn convert_whitenoise_to_data(whitenoise: &Whitenoise) -> WhitenoiseData {
    let mut accounts = HashMap::new();

    // Convert accounts from HashMap<PublicKey, Account> to HashMap<String, AccountData>
    for (pubkey, account) in &whitenoise.accounts {
        let pubkey_string = pubkey.to_hex();
        let account_data = convert_account_to_data(account);
        accounts.insert(pubkey_string, account_data);
    }

    // Convert active_account from Option<PublicKey> to Option<String>
    let active_account = whitenoise.active_account.as_ref().map(|pk| pk.to_hex());

    WhitenoiseData {
        config: convert_config_to_data(&whitenoise.config),
        accounts,
        active_account,
    }
}

pub fn convert_config_to_data(config: &WhitenoiseConfig) -> WhitenoiseConfigData {
    WhitenoiseConfigData {
        data_dir: config.data_dir.to_string_lossy().to_string(),
        logs_dir: config.logs_dir.to_string_lossy().to_string(),
    }
}

pub fn convert_account_to_data(account: &Account) -> AccountData {
    AccountData {
        pubkey: account.pubkey.to_hex(),
        settings: account.settings.clone(),
        onboarding: account.onboarding.clone(),
        last_synced: account.last_synced.as_u64(),
    }
}

// Helper function to create a WhitenoiseConfig from String paths (since Dart can't pass &Path directly)
pub fn create_whitenoise_config(data_dir: String, logs_dir: String) -> WhitenoiseConfig {
    WhitenoiseConfig::new(Path::new(&data_dir), Path::new(&logs_dir))
}

// Wrapper for Whitenoise::initialize_whitenoise to make it available to Dart
// Returns the original Whitenoise object so you can call methods on it
pub async fn initialize_whitenoise(
    config: WhitenoiseConfig,
) -> Result<Whitenoise, WhitenoiseError> {
    Whitenoise::initialize_whitenoise(config).await
}

// Data extraction methods - use these when Flutter needs to access fields
pub fn get_whitenoise_data(whitenoise: &Whitenoise) -> WhitenoiseData {
    convert_whitenoise_to_data(whitenoise)
}

pub fn get_account_data(account: &Account) -> AccountData {
    convert_account_to_data(account)
}

pub fn get_config_data(config: &WhitenoiseConfig) -> WhitenoiseConfigData {
    convert_config_to_data(config)
}

pub async fn delete_all_data(whitenoise: &mut Whitenoise) -> Result<(), WhitenoiseError> {
    whitenoise.delete_all_data().await
}

// ================================
// Account methods
// ================================

pub async fn create_identity(whitenoise: &mut Whitenoise) -> Result<Account, WhitenoiseError> {
    whitenoise.create_identity().await
}

pub async fn login(
    whitenoise: &mut Whitenoise,
    nsec_or_hex_privkey: String,
) -> Result<Account, WhitenoiseError> {
    whitenoise.login(nsec_or_hex_privkey).await
}

pub async fn logout(whitenoise: &mut Whitenoise, account: &Account) -> Result<(), WhitenoiseError> {
    whitenoise.logout(account).await
}

pub fn update_active_account(
    whitenoise: &mut Whitenoise,
    account: &Account,
) -> Result<Account, WhitenoiseError> {
    whitenoise.update_active_account(account)
}

pub fn export_account_nsec(
    whitenoise: &Whitenoise,
    account: &Account,
) -> Result<String, WhitenoiseError> {
    whitenoise.export_account_nsec(account)
}

pub fn export_account_npub(
    whitenoise: &Whitenoise,
    account: &Account,
) -> Result<String, WhitenoiseError> {
    whitenoise.export_account_npub(account)
}

pub fn get_active_account(whitenoise: &Whitenoise) -> Result<Option<Account>, WhitenoiseError> {
    if let Some(active_account) = whitenoise.active_account {
        Ok(whitenoise.accounts.get(&active_account).cloned())
    } else {
        Ok(None)
    }
}

// ================================
// Data loading methods
// ================================

pub async fn load_metadata(
    whitenoise: &Whitenoise,
    pubkey: PublicKey,
) -> Result<Option<Metadata>, WhitenoiseError> {
    whitenoise.load_metadata(pubkey).await
}

pub async fn update_metadata(
    whitenoise: &Whitenoise,
    metadata: &Metadata,
    account: &Account,
) -> Result<(), WhitenoiseError> {
    whitenoise.update_metadata(metadata, account).await
}

pub async fn load_relays(
    whitenoise: &Whitenoise,
    pubkey: PublicKey,
    relay_type: RelayType,
) -> Result<Vec<RelayUrl>, WhitenoiseError> {
    whitenoise.load_relays(pubkey, relay_type).await
}

pub async fn load_key_package(
    whitenoise: &Whitenoise,
    pubkey: PublicKey,
) -> Result<Option<Event>, WhitenoiseError> {
    whitenoise.load_key_package(pubkey).await
}

pub async fn load_onboarding_state(
    whitenoise: &Whitenoise,
    pubkey: PublicKey,
) -> Result<OnboardingState, WhitenoiseError> {
    whitenoise.load_onboarding_state(pubkey).await
}

// ================================
// Contact methods
// ================================

pub async fn load_contact_list(
    whitenoise: &Whitenoise,
    pubkey: PublicKey,
) -> Result<HashMap<PublicKey, Option<Metadata>>, WhitenoiseError> {
    whitenoise.load_contact_list(pubkey).await
}

pub async fn add_contact(
    whitenoise: &Whitenoise,
    account: &Account,
    contact_pubkey: PublicKey,
) -> Result<(), WhitenoiseError> {
    whitenoise.add_contact(account, contact_pubkey).await
}

pub async fn remove_contact(
    whitenoise: &Whitenoise,
    account: &Account,
    contact_pubkey: PublicKey,
) -> Result<(), WhitenoiseError> {
    whitenoise.remove_contact(account, contact_pubkey).await
}

pub async fn update_contacts(
    whitenoise: &Whitenoise,
    account: &Account,
    contact_pubkeys: Vec<PublicKey>,
) -> Result<(), WhitenoiseError> {
    whitenoise.update_contacts(account, contact_pubkeys).await
}
