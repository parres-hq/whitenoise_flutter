// pub mod accounts;

// Re-export everything from the whitenoise crate
pub use whitenoise::{Account, AccountSettings, OnboardingState, Whitenoise, WhitenoiseConfig, WhitenoiseError};

use std::path::Path;
use std::collections::HashMap;

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
pub async fn initialize_whitenoise(config: WhitenoiseConfig) -> Result<Whitenoise, WhitenoiseError> {
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

// Original wrapper methods - these return opaque types for method calls
pub async fn create_identity(whitenoise: &mut Whitenoise) -> Result<Account, WhitenoiseError> {
    whitenoise.create_identity().await
}

pub async fn login(whitenoise: &mut Whitenoise, nsec_or_hex_privkey: String) -> Result<Account, WhitenoiseError> {
    whitenoise.login(nsec_or_hex_privkey).await
}

pub async fn logout(whitenoise: &mut Whitenoise, account: &Account) -> Result<(), WhitenoiseError> {
    whitenoise.logout(account).await
}

pub fn update_active_account(whitenoise: &mut Whitenoise, account: &Account) -> Result<Account, WhitenoiseError> {
    whitenoise.update_active_account(account)
}
