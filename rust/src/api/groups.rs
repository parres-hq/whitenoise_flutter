use crate::api::utils::group_id_to_string;
use chrono::{DateTime, Utc};
use flutter_rust_bridge::frb;
use hex;
use whitenoise::{Group as WhitenoiseGroup, GroupType, NostrGroupConfigData, Whitenoise, WhitenoiseError};
pub use whitenoise::{GroupId, GroupState, PublicKey, RelayType};

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

#[frb]
pub async fn fetch_groups(pubkey: &PublicKey) -> Result<Vec<Group>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.find_account_by_pubkey(pubkey).await?;
    let groups = whitenoise.fetch_groups(&account, true).await?;
    Ok(groups.into_iter().map(|g| g.into()).collect())
}

#[frb]
pub async fn fetch_group_members(
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
) -> Result<Vec<PublicKey>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.find_account_by_pubkey(pubkey).await?;
    whitenoise.fetch_group_members(&account, &group_id).await
}

#[frb]
pub async fn fetch_group_admins(
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
) -> Result<Vec<PublicKey>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.find_account_by_pubkey(pubkey).await?;
    whitenoise.fetch_group_admins(&account, &group_id).await
}

#[frb]
pub async fn create_group(
    creator_pubkey: &PublicKey,
    member_pubkeys: Vec<PublicKey>,
    admin_pubkeys: Vec<PublicKey>,
    group_name: String,
    group_description: String,
) -> Result<Group, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let creator_account = whitenoise.find_account_by_pubkey(creator_pubkey).await?;

    // Fetch the creator's Nostr relays to include in the group configuration
    let nostr_relays = creator_account.relays(RelayType::Nip65, whitenoise).await?;

    let nostr_group_config = NostrGroupConfigData {
        name: group_name,
        description: group_description,
        image_key: None,
        image_url: None,
        relays: nostr_relays.into_iter().map(|r| r.url).collect(),
    };

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
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
    member_pubkeys: Vec<PublicKey>,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.find_account_by_pubkey(pubkey).await?;
    whitenoise
        .add_members_to_group(&account, &group_id, member_pubkeys)
        .await
}

#[frb]
pub async fn remove_members_from_group(
    pubkey: &PublicKey,
    group_id: whitenoise::GroupId,
    member_pubkeys: Vec<PublicKey>,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.find_account_by_pubkey(pubkey).await?;
    whitenoise
        .remove_members_from_group(&account, &group_id, member_pubkeys)
        .await
}
