use crate::api::{group_id_from_string, utils::group_id_to_string};
use chrono::{DateTime, Utc};
use flutter_rust_bridge::frb;
use hex;
use whitenoise::{Group as WhitenoiseGroup, NostrGroupConfigData, Whitenoise, WhitenoiseError};
pub use whitenoise::{GroupId, GroupState, GroupType, PublicKey, RelayType};

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
    pub group_type: GroupType,
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
            group_type: group.group_type,
            epoch: group.epoch,
            state: group.state,
        }
    }
}

#[frb(mirror(GroupState))]
#[derive(Debug, Clone)]
pub enum _GroupState {
    Active,
    Inactive,
    Pending,
}

#[frb(mirror(GroupType))]
#[derive(Debug, Clone)]
pub enum _GroupType {
    DirectMessage,
    Group,
}

#[frb]
pub async fn active_groups(pubkey: String) -> Result<Vec<Group>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let groups = whitenoise.groups(&account, true).await?;
    Ok(groups.into_iter().map(|g| g.into()).collect())
}

#[frb]
pub async fn group_members(
    pubkey: String,
    group_id: String,
) -> Result<Vec<String>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let group_id = group_id_from_string(&group_id)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let members = whitenoise.group_members(&account, &group_id).await?;
    Ok(members.into_iter().map(|m| m.to_hex()).collect())
}

#[frb]
pub async fn group_admins(
    pubkey: String,
    group_id: String,
) -> Result<Vec<String>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
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
) -> Result<Group, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let creator_pubkey = PublicKey::from_hex(&creator_pubkey)?;
    let creator_account = whitenoise.find_account_by_pubkey(&creator_pubkey).await?;

    // Fetch the creator's Nostr relays to include in the group configuration
    let nostr_relays = creator_account.relays(RelayType::Nip65, whitenoise).await?;

    let nostr_group_config = NostrGroupConfigData {
        name: group_name,
        description: group_description,
        image_key: None,
        image_url: None,
        relays: nostr_relays.into_iter().map(|r| r.url).collect(),
    };

    let member_pubkeys = member_pubkeys.into_iter().map(|pk| PublicKey::from_hex(&pk)).collect::<Result<Vec<_>, _>>()?;
    let admin_pubkeys = admin_pubkeys.into_iter().map(|pk| PublicKey::from_hex(&pk)).collect::<Result<Vec<_>, _>>()?;

    let group = whitenoise
        .create_group(
            &creator_account,
            member_pubkeys,
            admin_pubkeys,
            nostr_group_config,
            None,
        )
        .await?;
    Ok(group.into())
}

#[frb]
pub async fn add_members_to_group(
    pubkey: String,
    group_id: String,
    member_pubkeys: Vec<String>,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let group_id = group_id_from_string(&group_id)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let member_pubkeys = member_pubkeys.into_iter().map(|pk| PublicKey::from_hex(&pk)).collect::<Result<Vec<_>, _>>()?;
    whitenoise
        .add_members_to_group(&account, &group_id, member_pubkeys)
        .await
}

#[frb]
pub async fn remove_members_from_group(
    pubkey: String,
    group_id: String,
    member_pubkeys: Vec<String>,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let group_id = group_id_from_string(&group_id)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let member_pubkeys = member_pubkeys.into_iter().map(|pk| PublicKey::from_hex(&pk)).collect::<Result<Vec<_>, _>>()?;
    whitenoise
        .remove_members_from_group(&account, &group_id, member_pubkeys)
        .await
}
