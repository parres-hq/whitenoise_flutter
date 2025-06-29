// Re-export everything from the whitenoise crate
use std::collections::{BTreeMap, HashMap};
use std::path::Path;
pub use whitenoise::{
    Account, AccountSettings, Event, Group, GroupId, GroupState, GroupType, Kind,
    MessageWithTokens, Metadata, OnboardingState, PublicKey, RelayType, RelayUrl, Tag, Whitenoise,
    WhitenoiseConfig, WhitenoiseError,
};

use flutter_rust_bridge::frb;
use hex;

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

#[derive(Debug, Clone)]
pub struct MessageWithTokensData {
    pub id: String,
    pub pubkey: String,
    pub kind: u16,
    pub created_at: u64,
    pub content: Option<String>,
    pub tokens: Vec<String>, // Simplified tokens representation
}

/// Helper function to convert MessageWithTokens to MessageWithTokensData
pub fn convert_message_with_tokens_to_data(
    message_with_tokens: &MessageWithTokens,
) -> MessageWithTokensData {
    // Convert tokens to simplified string representation
    let tokens = message_with_tokens
        .tokens
        .iter()
        .map(|token| format!("{:?}", token))
        .collect();

    MessageWithTokensData {
        id: message_with_tokens.message.id.to_hex(),
        pubkey: message_with_tokens.message.pubkey.to_hex(),
        kind: message_with_tokens.message.kind.as_u16(),
        created_at: message_with_tokens.message.created_at.as_u64(),
        content: Some(message_with_tokens.message.content.clone()),
        tokens,
    }
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

/// Helper function to convert a relay type to a RelayType
pub fn relay_type_nostr() -> RelayType {
    RelayType::Nostr
}

/// Helper function to convert a relay type to a RelayType
pub fn relay_type_inbox() -> RelayType {
    RelayType::Inbox
}

/// Helper function to convert a relay type to a RelayType
pub fn relay_type_key_package() -> RelayType {
    RelayType::KeyPackage
}

/// Helper function to convert a public key string to a PublicKey
pub fn public_key_from_string(public_key_string: String) -> Result<PublicKey, WhitenoiseError> {
    PublicKey::parse(&public_key_string).map_err(WhitenoiseError::from)
}

/// Helper function to convert a relay url string to a RelayUrl
pub fn relay_url_from_string(url: String) -> Result<RelayUrl, WhitenoiseError> {
    RelayUrl::parse(&url).map_err(WhitenoiseError::from)
}

/// Helper function to convert a RelayUrl to a string
pub fn string_from_relay_url(relay_url: &RelayUrl) -> String {
    relay_url.to_string()
}

/// Helper function to convert a GroupId to a hex string
pub fn group_id_to_string(group_id: &GroupId) -> String {
    // Convert GroupId to hex string using as_slice() method and hex crate
    hex::encode(group_id.as_slice())
}

/// Helper function to convert a hex string to a GroupId
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

/// Helper function to convert a Group to GroupData
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

/// Helper function to convert a WhitenoiseConfig to WhitenoiseConfigData
pub fn convert_config_to_data(config: &WhitenoiseConfig) -> WhitenoiseConfigData {
    WhitenoiseConfigData {
        data_dir: config.data_dir.to_string_lossy().to_string(),
        logs_dir: config.logs_dir.to_string_lossy().to_string(),
    }
}

/// Helper function to convert an Account to AccountData
pub fn convert_account_to_data(account: &Account) -> AccountData {
    AccountData {
        pubkey: account.pubkey.to_hex(),
        settings: account.settings.clone(),
        onboarding: account.onboarding.clone(),
        last_synced: account.last_synced.as_u64(),
    }
}

/// Helper function to convert a vec of strings to a tag
pub fn tag_from_vec(vec: Vec<String>) -> Result<Tag, WhitenoiseError> {
    Tag::parse(vec).map_err(WhitenoiseError::from)
}

// ================================
// Initialization / Teardown methods
// ================================

/// Wrapper for Whitenoise::initialize_whitenoise to make it available to Dart
/// Must be called before any other methods are called.
pub async fn initialize_whitenoise(config: WhitenoiseConfig) -> Result<(), WhitenoiseError> {
    Whitenoise::initialize_whitenoise(config).await
}

/// Delete all data from the whitenoise instance.
/// This logs out all the accounts and removes all local data from the app.
pub async fn delete_all_data() -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.delete_all_data().await
}

// ================================
// Account methods
// ================================

/// Fetch all accounts that are stored on the whitenoise instance (these are "logged in" accounts)
pub async fn fetch_accounts() -> Result<Vec<AccountData>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let accounts = whitenoise.fetch_accounts().await?;
    Ok(accounts.values().map(convert_account_to_data).collect())
}

/// Fetch an account by its public key
pub async fn fetch_account(pubkey: &PublicKey) -> Result<AccountData, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    Ok(convert_account_to_data(&account))
}

/// Create a new account and get it ready for MLS messaging
pub async fn create_identity() -> Result<Account, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.create_identity().await
}

/// Login to an account by its private key (nsec or hex)
pub async fn login(nsec_or_hex_privkey: String) -> Result<Account, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.login(nsec_or_hex_privkey).await
}

/// Logout of an account by its public key
pub async fn logout(pubkey: &PublicKey) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.logout(pubkey).await
}

/// Export an account's private key (nsec)
pub async fn export_account_nsec(pubkey: &PublicKey) -> Result<String, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.export_account_nsec(&account).await
}

/// Export an account's public key (npub)
pub async fn export_account_npub(pubkey: &PublicKey) -> Result<String, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.export_account_npub(&account).await
}

// ================================
// Data loading methods
// ================================

/// Fetch an account's metadata by its public key
pub async fn fetch_metadata(pubkey: PublicKey) -> Result<Option<MetadataData>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let metadata = whitenoise.fetch_metadata(pubkey).await?;
    Ok(metadata.map(|m| convert_metadata_to_data(&m)))
}

/// Update an account's metadata
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

/// Fetch an account's relays by its public key and the type of relay
pub async fn fetch_relays(
    pubkey: PublicKey,
    relay_type: RelayType,
) -> Result<Vec<RelayUrl>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.fetch_relays(pubkey, relay_type).await
}

/// Update an account's relays
pub async fn update_relays(
    pubkey: &PublicKey,
    relay_type: RelayType,
    relays: Vec<RelayUrl>,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.update_relays(&account, relay_type, relays).await
}

/// Fetch an account's key package by its public key, this gets a key package from relays
pub async fn fetch_key_package(pubkey: PublicKey) -> Result<Option<Event>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let relays = whitenoise
        .fetch_relays(pubkey, RelayType::KeyPackage)
        .await?;
    whitenoise.fetch_key_package_event(pubkey, relays).await
}

/// Fetch an account's onboarding state by its public key
pub async fn fetch_onboarding_state(pubkey: PublicKey) -> Result<OnboardingState, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.fetch_onboarding_state(pubkey).await
}

// ================================
// Contact methods
// ================================

/// Fetch an account's contacts by its public key
pub async fn fetch_contacts(
    pubkey: PublicKey,
) -> Result<HashMap<PublicKey, Option<MetadataData>>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
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

/// Add a contact to an account's contacts
pub async fn add_contact(
    pubkey: &PublicKey,
    contact_pubkey: PublicKey,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.add_contact(&account, contact_pubkey).await
}

/// Remove a contact from an account's contacts
pub async fn remove_contact(
    pubkey: &PublicKey,
    contact_pubkey: PublicKey,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.remove_contact(&account, contact_pubkey).await
}

/// Update an account's contact list in one go. Overwrites the entire contact list.
pub async fn update_contacts(
    pubkey: &PublicKey,
    contact_pubkeys: Vec<PublicKey>,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.update_contacts(&account, contact_pubkeys).await
}

// ================================
// Group methods
// ================================

/// Fetch all active groups for an account
pub async fn fetch_groups(pubkey: &PublicKey) -> Result<Vec<GroupData>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    let groups = whitenoise.fetch_groups(&account, true).await?;
    Ok(groups.iter().map(convert_group_to_data).collect())
}

/// Fetch group members for a group
pub async fn fetch_group_members(
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
) -> Result<Vec<PublicKey>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.fetch_group_members(&account, &group_id).await
}

/// Fetch groups admins for a group
pub async fn fetch_group_admins(
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
) -> Result<Vec<PublicKey>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.fetch_group_admins(&account, &group_id).await
}

/// Create a group
pub async fn create_group(
    creator_pubkey: &PublicKey,
    member_pubkeys: Vec<PublicKey>,
    admin_pubkeys: Vec<PublicKey>,
    group_name: String,
    group_description: String,
) -> Result<GroupData, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let creator_account = whitenoise.fetch_account(creator_pubkey).await?;
    let group = tokio::task::spawn_blocking(move || {
        tokio::runtime::Handle::current().block_on(whitenoise.create_group(
            &creator_account,
            member_pubkeys,
            admin_pubkeys,
            group_name,
            group_description,
        ))
    })
    .await
    .map_err(|e| WhitenoiseError::from(std::io::Error::other(e)))??;
    Ok(convert_group_to_data(&group))
}

/// Send a message to a group
///
/// This method sends a message to the specified group using the MLS protocol.
/// The message will be encrypted and delivered to all group members.
///
/// # Arguments
/// * `pubkey` - The public key of the account sending the message
/// * `group_id` - The MLS group ID to send the message to
/// * `message` - The message content as a string
/// * `kind` - The Nostr event kind (e.g., 1 for text message, 5 for delete)
/// * `tags` - Optional Nostr tags to include with the message (use the `tag_from_vec` helper function to convert a vec of strings to a tag)
///
/// # Returns
/// * `Ok(MessageWithTokensData)` - The sent message and parsed tokens if successful
/// * `Err(WhitenoiseError)` - If there was an error sending the message
pub async fn send_message(
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
    message: String,
    kind: u16,
    tags: Option<Vec<Tag>>,
) -> Result<MessageWithTokensData, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey_clone = *pubkey;
    let message_with_tokens = tokio::task::spawn_blocking(move || {
        tokio::runtime::Handle::current().block_on(whitenoise.send_message(
            &pubkey_clone,
            &group_id,
            message,
            kind,
            tags,
        ))
    })
    .await
    .map_err(|e| WhitenoiseError::from(std::io::Error::other(e)))??;
    Ok(convert_message_with_tokens_to_data(&message_with_tokens))
}

/// This method adds new members to an existing MLS group. The calling account must have
/// administrative privileges for the group. The operation will update the group's MLS
/// epoch and distribute the updated group state to all existing members.
///
/// # Arguments
/// * `pubkey` - The public key of the account performing the operation (must be a group admin)
/// * `group_id` - The MLS group ID to add members to
/// * `member_pubkeys` - A vector of public keys for the new members to add
///
/// # Returns
/// * `Ok(())` - If the members were successfully added to the group
/// * `Err(WhitenoiseError)` - If there was an error adding members (e.g., insufficient permissions, invalid group ID, or MLS protocol errors)
///
/// # Notes
/// * Only group administrators can add new members
/// * Each new member must have a valid key package published to relays
/// * The group epoch will be incremented after successful member addition
/// * All existing group members will receive an update with the new group composition
pub async fn add_members_to_group(
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
    member_pubkeys: Vec<PublicKey>,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    tokio::task::spawn_blocking(move || {
        tokio::runtime::Handle::current().block_on(whitenoise.add_members_to_group(
            &account,
            &group_id,
            member_pubkeys,
        ))
    })
    .await
    .map_err(|e| WhitenoiseError::from(std::io::Error::other(e)))?
}

/// This method removes existing members from an MLS group. The calling account must have
/// administrative privileges for the group. The operation will update the group's MLS
/// epoch and distribute the updated group state to all remaining members.
///
/// # Arguments
/// * `pubkey` - The public key of the account performing the operation (must be a group admin)
/// * `group_id` - The MLS group ID to remove members from
/// * `member_pubkeys` - A vector of public keys for the members to remove
///
/// # Returns
/// * `Ok(())` - If the members were successfully removed from the group
/// * `Err(WhitenoiseError)` - If there was an error removing members (e.g., insufficient permissions, invalid group ID, member not found, or MLS protocol errors)
///
/// # Notes
/// * Only group administrators can remove members
/// * Administrators cannot remove themselves from the group
/// * Removed members will lose access to future group messages
/// * The group epoch will be incremented after successful member removal
/// * All remaining group members will receive an update with the new group composition
/// * Removed members will not be notified of their removal through the MLS protocol
pub async fn remove_members_from_group(
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
    member_pubkeys: Vec<PublicKey>,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    tokio::task::spawn_blocking(move || {
        tokio::runtime::Handle::current().block_on(whitenoise.remove_members_from_group(
            &account,
            &group_id,
            member_pubkeys,
        ))
    })
    .await
    .map_err(|e| WhitenoiseError::from(std::io::Error::other(e)))?
}
