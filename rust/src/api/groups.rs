use flutter_rust_bridge::frb;
use hex;
pub use whitenoise::{
    Group, GroupId, GroupState, GroupType, NostrGroupConfigData, PublicKey, Whitenoise,
    WhitenoiseError,
};

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

/// Converts a `GroupId` to its hexadecimal string representation.
///
/// This function is used to serialize GroupId objects for storage or transmission
/// to Flutter, as GroupId cannot be directly serialized across the bridge.
///
/// # Parameters
/// * `group_id` - Reference to a GroupId object
///
/// # Returns
/// Hexadecimal string representation of the group ID
#[frb]
pub fn group_id_to_string(group_id: &GroupId) -> String {
    // Convert GroupId to hex string using as_slice() method and hex crate
    hex::encode(group_id.as_slice())
}

/// Converts a hexadecimal string back to a `GroupId` object.
///
/// This function deserializes a hex string representation back into a GroupId
/// object for use with the core Whitenoise library.
///
/// # Parameters
/// * `hex_string` - Hexadecimal string representation of a group ID
///
/// # Returns
/// * `Ok(GroupId)` - Successfully parsed group ID
/// * `Err(WhitenoiseError)` - If the hex string is invalid or malformed
#[frb]
pub fn group_id_from_string(hex_string: String) -> Result<GroupId, WhitenoiseError> {
    // Convert hex string back to GroupId using from_slice() method and hex crate
    let bytes = hex::decode(hex_string).map_err(|e| {
        let json_error = serde_json::Error::io(std::io::Error::new(
            std::io::ErrorKind::InvalidData,
            format!("Hex decode error: {e}"),
        ));
        WhitenoiseError::from(json_error)
    })?;
    Ok(GroupId::from_slice(&bytes))
}

/// Converts a core `Group` object to a Flutter-compatible `GroupData` structure.
///
/// This function handles the conversion of complex types like timestamps, public keys,
/// and group IDs to their string representations for Flutter compatibility.
///
/// # Parameters
/// * `group` - Reference to a core Group object
///
/// # Returns
/// A GroupData struct with all fields converted for Flutter compatibility
#[frb]
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

/// Fetches all active groups that an account is a member of.
///
/// This function retrieves all groups where the specified account is an active member,
/// returning them as Flutter-compatible GroupData structures.
///
/// # Parameters
/// * `pubkey` - The public key of the account whose groups to fetch
///
/// # Returns
/// * `Ok(Vec<GroupData>)` - Vector of group data for all active groups
/// * `Err(WhitenoiseError)` - If there was an error fetching groups or account not found
#[frb]
pub async fn fetch_groups(pubkey: &PublicKey) -> Result<Vec<GroupData>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    let groups = whitenoise.fetch_groups(&account, true).await?;
    Ok(groups.iter().map(convert_group_to_data).collect())
}

/// Fetches all members of a specific group.
///
/// This function retrieves the public keys of all current members in the specified group.
/// The requesting account must be a member of the group to access this information.
///
/// # Parameters
/// * `pubkey` - The public key of the account making the request (must be a group member)
/// * `group_id` - The unique identifier of the group
///
/// # Returns
/// * `Ok(Vec<PublicKey>)` - Vector of public keys for all group members
/// * `Err(WhitenoiseError)` - If there was an error fetching members or insufficient permissions
#[frb]
pub async fn fetch_group_members(
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
) -> Result<Vec<PublicKey>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.fetch_group_members(&account, &group_id).await
}

/// Fetches all administrators of a specific group.
///
/// This function retrieves the public keys of all administrators for the specified group.
/// Administrators have special privileges such as adding/removing members and managing group settings.
///
/// # Parameters
/// * `pubkey` - The public key of the account making the request (must be a group member)
/// * `group_id` - The unique identifier of the group
///
/// # Returns
/// * `Ok(Vec<PublicKey>)` - Vector of public keys for all group administrators
/// * `Err(WhitenoiseError)` - If there was an error fetching admins or insufficient permissions
#[frb]
pub async fn fetch_group_admins(
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
) -> Result<Vec<PublicKey>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.fetch_group_admins(&account, &group_id).await
}

/// Creates a new MLS group with specified members and administrators.
///
/// This function creates a new group using the MLS (Message Layer Security) protocol,
/// setting up the initial member list and administrative privileges. The creator
/// automatically becomes a group administrator.
///
/// # Parameters
/// * `creator_pubkey` - The public key of the account creating the group (becomes admin)
/// * `member_pubkeys` - Vector of public keys for initial group members
/// * `admin_pubkeys` - Vector of public keys for initial group administrators
/// * `group_name` - Human-readable name for the group
/// * `group_description` - Description of the group's purpose
///
/// # Returns
/// * `Ok(GroupData)` - The created group data if successful
/// * `Err(WhitenoiseError)` - If there was an error creating the group
///
/// # Notes
/// * All members must have published key packages to relays
/// * The creator is automatically added as both member and admin
/// * Group creation may take time as it involves MLS protocol setup
#[frb]
pub async fn create_group(
    creator_pubkey: &PublicKey,
    member_pubkeys: Vec<PublicKey>,
    admin_pubkeys: Vec<PublicKey>,
    group_name: String,
    group_description: String,
) -> Result<GroupData, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let creator_account = whitenoise.fetch_account(creator_pubkey).await?;

    // Fetch the creator's Nostr relays to include in the group configuration
    let nostr_relays = whitenoise.fetch_relays(*creator_pubkey, whitenoise::RelayType::Nostr).await?;

    let nostr_group_config = NostrGroupConfigData {
        name: group_name,
        description: group_description,
        image_key: None,
        image_url: None,
        relays: nostr_relays,
    };

    let group = tokio::task::spawn_blocking(move || {
        tokio::runtime::Handle::current().block_on(whitenoise.create_group(
            &creator_account,
            member_pubkeys,
            admin_pubkeys,
            nostr_group_config,
        ))
    })
    .await
    .map_err(|e| WhitenoiseError::from(std::io::Error::other(e)))??;
    Ok(convert_group_to_data(&group))
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
#[frb]
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
#[frb]
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
