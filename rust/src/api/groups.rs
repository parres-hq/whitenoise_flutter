use crate::api::{error::ApiError, group_id_from_string, group_id_to_string};
use chrono::{DateTime, Utc};
use flutter_rust_bridge::frb;
use nostr_mls::prelude::group_types::Group as WhitenoiseGroup;
use nostr_mls::prelude::group_types::GroupState as WhitenoiseGroupState;
use nostr_mls::prelude::NostrGroupConfigData;
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
    pub image_url: Option<String>,
    pub image_key: Option<Vec<u8>>,
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
            image_url: group.image_url,
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

impl Group {
    #[frb]
    pub async fn group_type(&self) -> Result<GroupType, ApiError> {
        let whitenoise = Whitenoise::get_instance()?;
        let mls_group_id = group_id_from_string(&self.mls_group_id)?;
        let group_information =
            WhitenoiseGroupInformation::get_by_mls_group_id(&mls_group_id, whitenoise).await?;
        Ok(group_information.group_type.into())
    }

    #[frb]
    pub async fn is_direct_message_type(&self) -> Result<bool, ApiError> {
        let whitenoise = Whitenoise::get_instance()?;
        let mls_group_id = group_id_from_string(&self.mls_group_id)?;
        let group_information =
            WhitenoiseGroupInformation::get_by_mls_group_id(&mls_group_id, whitenoise).await?;
        Ok(group_information.group_type == WhitenoiseGroupType::DirectMessage)
    }

    #[frb]
    pub async fn is_group_type(&self) -> Result<bool, ApiError> {
        let whitenoise = Whitenoise::get_instance()?;
        let mls_group_id = group_id_from_string(&self.mls_group_id)?;
        let group_information =
            WhitenoiseGroupInformation::get_by_mls_group_id(&mls_group_id, whitenoise).await?;
        Ok(group_information.group_type == WhitenoiseGroupType::Group)
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
    group_type: String,
) -> Result<Group, ApiError> {
    let whitenoise_group_type = match group_type.as_str() {
        "direct_message" => WhitenoiseGroupType::DirectMessage,
        "group" => WhitenoiseGroupType::Group,
        _ => {
            return Err(ApiError::InvalidGroupType {
                message: "can only be 'direct_message' or 'group'".to_string(),
            })
        }
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
        image_url: None,
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
pub async fn get_group_information(group_id: String) -> Result<GroupInformation, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let group_id = group_id_from_string(&group_id)?;
    Ok(
        WhitenoiseGroupInformation::get_by_mls_group_id(&group_id, &whitenoise)
            .await?
            .into(),
    )
}

#[frb]
pub async fn get_groups_informations(
    group_ids: Vec<String>,
) -> Result<Vec<GroupInformation>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let group_ids = group_ids
        .into_iter()
        .map(|id| group_id_from_string(&id))
        .collect::<Result<Vec<_>, _>>()?;
    Ok(
        WhitenoiseGroupInformation::get_by_mls_group_ids(&group_ids, &whitenoise)
            .await?
            .into_iter()
            .map(|info| info.into())
            .collect(),
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_create_group_invalid_group_type() {
        let result = create_group(
            "npub1test".to_string(),
            vec!["npub1member".to_string()],
            vec!["npub1admin".to_string()],
            "Test Group".to_string(),
            "Test Description".to_string(),
            "invalid_type".to_string(),
        )
        .await;

        assert!(result.is_err());
        match result.unwrap_err() {
            ApiError::InvalidGroupType { message } => {
                assert_eq!(message, "can only be 'direct_message' or 'group'");
            }
            _ => panic!("Expected InvalidGroupType error"),
        }
    }

    #[tokio::test]
    async fn test_create_group_valid_group_types() {
        // Test that valid group types don't immediately fail with InvalidGroupType
        // Note: These will likely fail with other errors (like invalid pubkeys or missing Whitenoise instance)
        // but they should NOT fail with InvalidGroupType

        let result_dm = create_group(
            "npub1test".to_string(),
            vec!["npub1member".to_string()],
            vec!["npub1admin".to_string()],
            "Test DM".to_string(),
            "Test Description".to_string(),
            "direct_message".to_string(),
        )
        .await;

        let result_group = create_group(
            "npub1test".to_string(),
            vec!["npub1member".to_string()],
            vec!["npub1admin".to_string()],
            "Test Group".to_string(),
            "Test Description".to_string(),
            "group".to_string(),
        )
        .await;

        // Both should fail, but NOT with InvalidGroupType
        assert!(result_dm.is_err());
        assert!(result_group.is_err());

        // Verify they don't fail with InvalidGroupType
        if let Err(ApiError::InvalidGroupType { .. }) = result_dm {
            panic!("direct_message should be a valid group type");
        }
        if let Err(ApiError::InvalidGroupType { .. }) = result_group {
            panic!("group should be a valid group type");
        }
    }
}
