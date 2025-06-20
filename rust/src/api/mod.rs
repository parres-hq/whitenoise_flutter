// Re-export everything from the whitenoise crate
use std::collections::{BTreeMap, HashMap};
use std::path::Path;
use std::sync::Arc;
pub use whitenoise::{
    Account, AccountSettings, Event, Group, GroupId, GroupState, GroupType, Metadata,
    OnboardingState, PublicKey, RelayType, RelayUrl, Whitenoise, WhitenoiseConfig, WhitenoiseError,
};

use flutter_rust_bridge::frb;
use hex;

// Flutter-compatible wrapper structs
#[derive(Debug, Clone)]
pub struct WhitenoiseData {
    pub config: WhitenoiseConfigData,
    pub accounts: HashMap<String, AccountData>,
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

#[derive(Debug, Clone)]
pub struct MetadataData {
    pub name: Option<String>,
    pub display_name: Option<String>,
    pub about: Option<String>,
    pub picture: Option<String>,
    pub banner: Option<String>,
    pub website: Option<String>,
    pub nip05: Option<String>,
    pub lud06: Option<String>,
    pub lud16: Option<String>,
    // Private field to avoid Flutter Rust Bridge auto-generation issues
    custom: BTreeMap<String, String>,
}

// Manual getter/setter for the custom field to convert to/from Map<String, String>
impl MetadataData {
    pub fn get_custom(&self) -> HashMap<String, String> {
        self.custom
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect()
    }

    pub fn set_custom(&mut self, custom_map: HashMap<String, String>) {
        self.custom = custom_map.into_iter().collect();
    }
}

#[derive(Debug, Clone)]
pub struct GroupData {
    pub mls_group_id: String,
    pub nostr_group_id: String,
    pub name: String,
    pub description: String,
    pub admin_pubkeys: Vec<String>,
    pub last_message_id: Option<String>,
    pub last_message_at: Option<u64>,
    pub group_type: GroupType,
    pub epoch: u64,
    pub state: GroupState,
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

pub fn convert_metadata_to_data(metadata: &Metadata) -> MetadataData {
    // Convert BTreeMap<String, serde_json::Value> to BTreeMap<String, String>
    let custom_string_map = metadata
        .custom
        .iter()
        .map(|(key, value)| {
            let string_value = match value {
                serde_json::Value::String(s) => s.clone(),
                serde_json::Value::Number(n) => n.to_string(),
                serde_json::Value::Bool(b) => b.to_string(),
                serde_json::Value::Null => "null".to_string(),
                _ => value.to_string(), // Arrays and objects become JSON strings
            };
            (key.clone(), string_value)
        })
        .collect();

    MetadataData {
        name: metadata.name.clone(),
        display_name: metadata.display_name.clone(),
        about: metadata.about.clone(),
        picture: metadata.picture.clone(),
        banner: metadata.banner.clone(),
        website: metadata.website.clone(),
        nip05: metadata.nip05.clone(),
        lud06: metadata.lud06.clone(),
        lud16: metadata.lud16.clone(),
        custom: custom_string_map,
    }
}

pub fn convert_metadata_data_to_metadata(metadata_data: &MetadataData) -> Metadata {
    // Convert BTreeMap<String, String> back to BTreeMap<String, serde_json::Value>
    let custom_value_map = metadata_data
        .custom
        .iter()
        .map(|(key, value)| {
            // Try to parse as JSON first, fall back to string
            let json_value = serde_json::from_str(value)
                .unwrap_or_else(|_| serde_json::Value::String(value.clone()));
            (key.clone(), json_value)
        })
        .collect();

    Metadata {
        name: metadata_data.name.clone(),
        display_name: metadata_data.display_name.clone(),
        about: metadata_data.about.clone(),
        picture: metadata_data.picture.clone(),
        banner: metadata_data.banner.clone(),
        website: metadata_data.website.clone(),
        nip05: metadata_data.nip05.clone(),
        lud06: metadata_data.lud06.clone(),
        lud16: metadata_data.lud16.clone(),
        custom: custom_value_map,
    }
}

#[frb(mirror(GroupType))]
#[derive(Debug, Clone)]
pub enum _GroupType {
    DirectMessage,
    Group,
}

#[frb(mirror(GroupState))]
#[derive(Debug, Clone)]
pub enum _GroupState {
    Active,
    Inactive,
    Pending,
}

// ================================
// Type Helpers & Conversion Methods
// ================================

pub fn relay_type_nostr() -> RelayType {
    RelayType::Nostr
}

pub fn relay_type_inbox() -> RelayType {
    RelayType::Inbox
}

pub fn relay_type_key_package() -> RelayType {
    RelayType::KeyPackage
}

pub fn public_key_from_string(public_key_string: String) -> Result<PublicKey, WhitenoiseError> {
    PublicKey::parse(&public_key_string).map_err(WhitenoiseError::from)
}

pub fn relay_url_from_string(url: String) -> Result<RelayUrl, WhitenoiseError> {
    RelayUrl::parse(&url).map_err(WhitenoiseError::from)
}

pub fn get_relay_url_string(relay_url: &RelayUrl) -> String {
    relay_url.to_string()
}

pub async fn convert_whitenoise_to_data(whitenoise: &Arc<Whitenoise>) -> WhitenoiseData {
    let mut converted_accounts = HashMap::new();

    // Convert accounts from HashMap<PublicKey, Account> to HashMap<String, AccountData>
    let accounts_guard = whitenoise.accounts.read().await;
    for (pubkey, account) in accounts_guard.iter() {
        let pubkey_string = pubkey.to_hex();
        let account_data = convert_account_to_data(account);
        converted_accounts.insert(pubkey_string, account_data);
    }

    WhitenoiseData {
        config: convert_config_to_data(&whitenoise.config),
        accounts: converted_accounts,
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

pub fn group_id_to_string(group_id: &GroupId) -> String {
    // Convert GroupId to hex string using as_slice() method and hex crate
    hex::encode(group_id.as_slice())
}

pub fn group_id_from_string(hex_string: String) -> Result<GroupId, WhitenoiseError> {
    // Convert hex string back to GroupId using from_slice() method and hex crate
    let bytes = hex::decode(hex_string).map_err(|e| {
        let json_error = serde_json::Error::io(std::io::Error::new(
            std::io::ErrorKind::InvalidData,
            format!("Hex decode error: {}", e),
        ));
        WhitenoiseError::from(json_error)
    })?;
    Ok(GroupId::from_slice(&bytes))
}

pub fn convert_group_to_data(group: &Group) -> GroupData {
    GroupData {
        mls_group_id: group_id_to_string(&group.mls_group_id),
        nostr_group_id: hex::encode(group.nostr_group_id),
        name: group.name.clone(),
        description: group.description.clone(),
        admin_pubkeys: group.admin_pubkeys.iter().map(|pk| pk.to_hex()).collect(),
        last_message_id: group.last_message_id.map(|id| id.to_hex()),
        last_message_at: group.last_message_at.map(|at| at.as_u64()),
        group_type: group.group_type,
        epoch: group.epoch,
        state: group.state,
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
) -> Result<Arc<Whitenoise>, WhitenoiseError> {
    Whitenoise::initialize_whitenoise(config).await
}

// Data extraction methods - use these when Flutter needs to access fields
pub async fn get_whitenoise_data(whitenoise: &Arc<Whitenoise>) -> WhitenoiseData {
    convert_whitenoise_to_data(whitenoise).await
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

pub async fn logout(
    whitenoise: &mut Whitenoise,
    pubkey: &PublicKey,
) -> Result<(), WhitenoiseError> {
    whitenoise.logout(pubkey).await
}

pub async fn export_account_nsec(
    whitenoise: &Whitenoise,
    account: &Account,
) -> Result<String, WhitenoiseError> {
    whitenoise.export_account_nsec(account).await
}

pub async fn export_account_npub(
    whitenoise: &Whitenoise,
    account: &Account,
) -> Result<String, WhitenoiseError> {
    whitenoise.export_account_npub(account).await
}

// ================================
// Data loading methods
// ================================

pub async fn fetch_metadata(
    whitenoise: &Whitenoise,
    pubkey: PublicKey,
) -> Result<Option<MetadataData>, WhitenoiseError> {
    let metadata = whitenoise.fetch_metadata(pubkey).await?;
    Ok(metadata.map(|m| convert_metadata_to_data(&m)))
}

pub async fn update_metadata(
    whitenoise: &Whitenoise,
    metadata: &MetadataData,
    account: &Account,
) -> Result<(), WhitenoiseError> {
    // Convert MetadataData back to Metadata for the whitenoise API
    let metadata_to_save = convert_metadata_data_to_metadata(metadata);
    whitenoise.update_metadata(&metadata_to_save, account).await
}

pub async fn fetch_relays(
    whitenoise: &Whitenoise,
    pubkey: PublicKey,
    relay_type: RelayType,
) -> Result<Vec<RelayUrl>, WhitenoiseError> {
    whitenoise.fetch_relays(pubkey, relay_type).await
}

pub async fn update_relays(
    whitenoise: &Whitenoise,
    account: &Account,
    relay_type: RelayType,
    relays: Vec<RelayUrl>,
) -> Result<(), WhitenoiseError> {
    whitenoise.update_relays(account, relay_type, relays).await
}

pub async fn fetch_key_package(
    whitenoise: &Whitenoise,
    pubkey: PublicKey,
) -> Result<Option<Event>, WhitenoiseError> {
    whitenoise.fetch_key_package_event(pubkey).await
}

pub async fn fetch_onboarding_state(
    whitenoise: &Whitenoise,
    pubkey: PublicKey,
) -> Result<OnboardingState, WhitenoiseError> {
    whitenoise.fetch_onboarding_state(pubkey).await
}

// ================================
// Contact methods
// ================================

pub async fn fetch_contacts(
    whitenoise: &Whitenoise,
    pubkey: PublicKey,
) -> Result<HashMap<PublicKey, Option<MetadataData>>, WhitenoiseError> {
    let contacts = whitenoise.fetch_contacts(pubkey).await?;
    let converted_contacts = contacts
        .into_iter()
        .map(|(pk, metadata_opt)| {
            let converted_metadata = metadata_opt.map(|m| convert_metadata_to_data(&m));
            (pk, converted_metadata)
        })
        .collect();
    Ok(converted_contacts)
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

// ================================
// Group methods
// ================================

/// Fetch all active groups for an account
pub async fn fetch_groups(
    whitenoise: &Whitenoise,
    account: &Account,
) -> Result<Vec<GroupData>, WhitenoiseError> {
    let groups = whitenoise.fetch_groups(account, true).await?;
    Ok(groups.iter().map(convert_group_to_data).collect())
}

/// Fetch group members for a group
pub async fn fetch_group_members(
    whitenoise: &Whitenoise,
    account: &Account,
    group_id: whitenoise::GroupId,
) -> Result<Vec<PublicKey>, WhitenoiseError> {
    whitenoise.fetch_group_members(account, &group_id).await
}

/// Fetch groups admins for a group
pub async fn fetch_group_admins(
    whitenoise: &Whitenoise,
    account: &Account,
    group_id: whitenoise::GroupId,
) -> Result<Vec<PublicKey>, WhitenoiseError> {
    whitenoise.fetch_group_admins(account, &group_id).await
}

// TODO: Temporarily commented out due to thread safety issues with SQLite RefCell in whitenoise crate
// /// Create a group
// pub async fn create_group(
//     whitenoise: &mut Whitenoise,
//     creator_account: &Account,
//     member_pubkeys: Vec<PublicKey>,
//     admin_pubkeys: Vec<PublicKey>,
//     group_name: String,
//     group_description: String,
// ) -> Result<GroupData, WhitenoiseError> {
//     let group = whitenoise
//         .create_group(
//             creator_account,
//             member_pubkeys,
//             admin_pubkeys,
//             group_name,
//             group_description,
//         )
//         .await?;
//     Ok(convert_group_to_data(&group))
// }
