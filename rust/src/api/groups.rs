use crate::api::{error::ApiError, group_id_from_string, group_id_to_string};
use chrono::{DateTime, Utc};
use flutter_rust_bridge::frb;
use mdk_core::prelude::group_types::Group as WhitenoiseGroup;
use mdk_core::prelude::group_types::GroupState as WhitenoiseGroupState;
use mdk_core::prelude::{NostrGroupConfigData, NostrGroupDataUpdate};
use nostr_sdk::prelude::*;
use whitenoise::{
    GroupInformation as WhitenoiseGroupInformation, GroupType as WhitenoiseGroupType, RelayType,
    Whitenoise,
};

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct Group {
    pub mls_group_id: String,
    pub nostr_group_id: String,
    pub name: String,
    pub description: String,
    pub image_hash: Option<[u8; 32]>,
    pub image_key: Option<[u8; 32]>,
    pub admin_pubkeys: Vec<String>,
    pub last_message_id: Option<String>,
    pub last_message_at: Option<DateTime<Utc>>,
    pub epoch: u64,
    pub state: GroupState,
}

impl From<WhitenoiseGroup> for Group {
    fn from(group: WhitenoiseGroup) -> Self {
        Self {
            mls_group_id: group_id_to_string(&group.mls_group_id),
            nostr_group_id: hex::encode(group.nostr_group_id),
            name: group.name,
            description: group.description,
            image_hash: group.image_hash,
            image_key: group.image_key,
            admin_pubkeys: group.admin_pubkeys.iter().map(|pk| pk.to_hex()).collect(),
            last_message_id: group.last_message_id.map(|id| id.to_hex()),
            last_message_at: group.last_message_at.map(|ts| {
                DateTime::from_timestamp(ts.as_u64() as i64, 0)
                    .unwrap_or_else(|| DateTime::from_timestamp(0, 0).unwrap())
            }),
            epoch: group.epoch,
            state: group.state.into(),
        }
    }
}

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct FlutterGroupDataUpdate {
    pub name: Option<String>,
    pub description: Option<String>,
    pub relays: Option<Vec<String>>,
    pub admins: Option<Vec<String>>,
    pub image_key: Option<[u8; 32]>,
    pub image_hash: Option<[u8; 32]>,
    pub image_nonce: Option<[u8; 12]>,
}

impl From<FlutterGroupDataUpdate> for NostrGroupDataUpdate {
    fn from(group_data: FlutterGroupDataUpdate) -> Self {
        Self {
            name: group_data.name,
            description: group_data.description,
            // Wrap in Some() to convert Option<T> to Option<Option<T>>
            // None means don't update, Some(value) means set to value
            image_key: group_data.image_key.map(Some),
            image_hash: group_data.image_hash.map(Some),
            image_nonce: group_data.image_nonce.map(Some),
            // Will silently drop invalid relay inputs
            relays: group_data.relays.map(|relays| {
                relays
                    .into_iter()
                    .filter_map(|r| RelayUrl::parse(&r).ok())
                    .collect()
            }),
            // Will silently drop invalid admin inputs
            admins: group_data.admins.map(|admins| {
                admins
                    .into_iter()
                    .filter_map(|a| PublicKey::parse(&a).ok())
                    .collect()
            }),
        }
    }
}

impl Group {
    #[frb]
    pub async fn group_type(&self, account_pubkey: String) -> Result<GroupType, ApiError> {
        let whitenoise = Whitenoise::get_instance()?;
        let mls_group_id = group_id_from_string(&self.mls_group_id)?;
        let parsed_pubkey = PublicKey::parse(&account_pubkey)?;
        let group_information = whitenoise
            .get_group_information_by_mls_group_id(parsed_pubkey, &mls_group_id)
            .await?;
        Ok(group_information.group_type.into())
    }

    #[frb]
    pub async fn is_direct_message_type(&self, account_pubkey: String) -> Result<bool, ApiError> {
        let whitenoise = Whitenoise::get_instance()?;
        let mls_group_id = group_id_from_string(&self.mls_group_id)?;
        let parsed_pubkey = PublicKey::parse(&account_pubkey)?;
        let group_information = whitenoise
            .get_group_information_by_mls_group_id(parsed_pubkey, &mls_group_id)
            .await?;
        Ok(group_information.group_type == WhitenoiseGroupType::DirectMessage)
    }

    #[frb]
    pub async fn is_group_type(&self, account_pubkey: String) -> Result<bool, ApiError> {
        let whitenoise = Whitenoise::get_instance()?;
        let mls_group_id = group_id_from_string(&self.mls_group_id)?;
        let parsed_pubkey = PublicKey::parse(&account_pubkey)?;
        let group_information = whitenoise
            .get_group_information_by_mls_group_id(parsed_pubkey, &mls_group_id)
            .await?;
        Ok(group_information.group_type == WhitenoiseGroupType::Group)
    }

    #[frb]
    pub async fn update_group_data(
        &self,
        account_pubkey: String,
        group_data: FlutterGroupDataUpdate,
    ) -> Result<(), ApiError> {
        let whitenoise = Whitenoise::get_instance()?;
        let mls_group_id = group_id_from_string(&self.mls_group_id)?;
        let parsed_pubkey = PublicKey::parse(&account_pubkey)?;
        let account = whitenoise.find_account_by_pubkey(&parsed_pubkey).await?;
        whitenoise
            .update_group_data(&account, &mls_group_id, group_data.into())
            .await
            .map_err(ApiError::from)
    }
}

// Define our own GroupState enum that can be used by Dart
#[frb]
#[derive(Debug, Clone)]
pub enum GroupState {
    Active,
    Inactive,
    Pending,
}

// Implement conversion from the whitenoise crate's GroupState to our GroupState
impl From<WhitenoiseGroupState> for GroupState {
    fn from(whitenoise_state: WhitenoiseGroupState) -> Self {
        match whitenoise_state {
            WhitenoiseGroupState::Active => GroupState::Active,
            WhitenoiseGroupState::Inactive => GroupState::Inactive,
            WhitenoiseGroupState::Pending => GroupState::Pending,
        }
    }
}

// Define our own GroupType enum that can be used by Dart
#[frb]
#[derive(Debug, Clone)]
pub enum GroupType {
    DirectMessage,
    Group,
}

// Implement conversion from the whitenoise crate's GroupType to our GroupType
impl From<WhitenoiseGroupType> for GroupType {
    fn from(whitenoise_type: WhitenoiseGroupType) -> Self {
        match whitenoise_type {
            WhitenoiseGroupType::DirectMessage => GroupType::DirectMessage,
            WhitenoiseGroupType::Group => GroupType::Group,
        }
    }
}

// Define our own GroupInformation struct that can be used by Dart
#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct GroupInformation {
    pub group_type: GroupType,
}

// Implement conversion from the whitenoise crate's GroupInformation to our GroupInformation
impl From<WhitenoiseGroupInformation> for GroupInformation {
    fn from(whitenoise_info: WhitenoiseGroupInformation) -> Self {
        Self {
            group_type: whitenoise_info.group_type.into(),
        }
    }
}

#[frb]
pub async fn active_groups(pubkey: String) -> Result<Vec<Group>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let groups = whitenoise.groups(&account, true).await?;
    Ok(groups.into_iter().map(|g| g.into()).collect())
}

#[frb]
pub async fn group_members(pubkey: String, group_id: String) -> Result<Vec<String>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let group_id = group_id_from_string(&group_id)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let members = whitenoise.group_members(&account, &group_id).await?;
    Ok(members.into_iter().map(|m| m.to_hex()).collect())
}

#[frb]
pub async fn group_admins(pubkey: String, group_id: String) -> Result<Vec<String>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let group_id = group_id_from_string(&group_id)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let admins = whitenoise.group_admins(&account, &group_id).await?;
    Ok(admins.into_iter().map(|a| a.to_hex()).collect())
}

#[frb]
pub async fn create_group(
    creator_pubkey: String,
    member_pubkeys: Vec<String>,
    admin_pubkeys: Vec<String>,
    group_name: String,
    group_description: String,
    group_type: GroupType,
) -> Result<Group, ApiError> {
    let whitenoise_group_type = match group_type {
        GroupType::DirectMessage => WhitenoiseGroupType::DirectMessage,
        GroupType::Group => WhitenoiseGroupType::Group,
    };

    let whitenoise = Whitenoise::get_instance()?;
    let creator_pubkey = PublicKey::parse(&creator_pubkey)?;
    let creator_account = whitenoise.find_account_by_pubkey(&creator_pubkey).await?;

    // Fetch the creator's Nostr relays to include in the group configuration
    let nostr_relays = creator_account.relays(RelayType::Nip65, whitenoise).await?;
    let admin_pubkeys = admin_pubkeys
        .into_iter()
        .map(|pk| PublicKey::parse(&pk))
        .collect::<Result<Vec<_>, _>>()?;

    let nostr_group_config = NostrGroupConfigData {
        name: group_name,
        description: group_description,
        image_key: None,
        image_hash: None,
        image_nonce: None,
        relays: nostr_relays.into_iter().map(|r| r.url).collect(),
        admins: admin_pubkeys,
    };

    let member_pubkeys = member_pubkeys
        .into_iter()
        .map(|pk| PublicKey::parse(&pk))
        .collect::<Result<Vec<_>, _>>()?;

    let group = whitenoise
        .create_group(
            &creator_account,
            member_pubkeys,
            nostr_group_config,
            Some(whitenoise_group_type),
        )
        .await?;
    Ok(group.into())
}

#[frb]
pub async fn add_members_to_group(
    pubkey: String,
    group_id: String,
    member_pubkeys: Vec<String>,
) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let group_id = group_id_from_string(&group_id)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let member_pubkeys = member_pubkeys
        .into_iter()
        .map(|pk| PublicKey::parse(&pk))
        .collect::<Result<Vec<_>, _>>()?;
    whitenoise
        .add_members_to_group(&account, &group_id, member_pubkeys)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn remove_members_from_group(
    pubkey: String,
    group_id: String,
    member_pubkeys: Vec<String>,
) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;
    let group_id = group_id_from_string(&group_id)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let member_pubkeys = member_pubkeys
        .into_iter()
        .map(|pk| PublicKey::parse(&pk))
        .collect::<Result<Vec<_>, _>>()?;
    whitenoise
        .remove_members_from_group(&account, &group_id, member_pubkeys)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn get_group_information(
    account_pubkey: String,
    group_id: String,
) -> Result<GroupInformation, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let group_id = group_id_from_string(&group_id)?;
    let parsed_pubkey = PublicKey::parse(&account_pubkey)?;
    Ok(whitenoise
        .get_group_information_by_mls_group_id(parsed_pubkey, &group_id)
        .await?
        .into())
}

#[frb]
pub async fn get_groups_informations(
    account_pubkey: String,
    group_ids: Vec<String>,
) -> Result<Vec<GroupInformation>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let group_ids = group_ids
        .into_iter()
        .map(|id| group_id_from_string(&id))
        .collect::<Result<Vec<_>, _>>()?;
    let parsed_pubkey = PublicKey::parse(&account_pubkey)?;
    Ok(whitenoise
        .get_group_information_by_mls_group_ids(parsed_pubkey, &group_ids)
        .await?
        .into_iter()
        .map(|info| info.into())
        .collect())
}

// Result structure for upload_group_image
#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct UploadGroupImageResult {
    pub encrypted_hash: [u8; 32],
    pub image_key: [u8; 32],
    pub image_nonce: [u8; 12],
}

#[frb]
pub async fn upload_group_image(
    account_pubkey: String,
    group_id: String,
    file_path: String,
    server_url: String,
) -> Result<UploadGroupImageResult, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let group_id = group_id_from_string(&group_id)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let server = Url::parse(&server_url)?;

    let (encrypted_hash, image_key, image_nonce) = whitenoise
        .upload_group_image(&account, &group_id, &file_path, server, None)
        .await?;

    Ok(UploadGroupImageResult {
        encrypted_hash,
        image_key,
        image_nonce,
    })
}

#[frb]
pub async fn get_group_image_path(
    account_pubkey: String,
    group_id: String,
) -> Result<Option<String>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let group_id = group_id_from_string(&group_id)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let path = whitenoise.get_group_image_path(&account, &group_id).await?;
    Ok(path.map(|p| p.to_string_lossy().to_string()))
}
