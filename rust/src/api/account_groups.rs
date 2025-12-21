use crate::api::{error::ApiError, utils::group_id_to_string};
use flutter_rust_bridge::frb;
use mdk_core::prelude::GroupId;
use nostr_sdk::prelude::*;
use whitenoise::AccountGroup as WhitenoiseAccountGroup;
use whitenoise::Whitenoise;

/// Represents the relationship between an account and an MLS group.
///
/// This struct tracks whether a user has accepted or declined a group invite.
/// When a welcome message is received, groups are auto-joined at the MLS level,
/// but the AccountGroup tracks the user's UI-level confirmation.
///
/// Confirmation states:
/// - `Pending` = auto-joined but awaiting user decision
/// - `Accepted` = user confirmed they want to see the group
/// - `Declined` = user chose to hide the group from UI
#[frb]
#[derive(Debug, Clone)]
pub struct AccountGroup {
    pub id: Option<i64>,
    pub account_pubkey: String,
    pub mls_group_id: String,
    pub user_confirmation: Option<bool>,
    pub created_at: i64,
    pub updated_at: i64,
}

impl From<WhitenoiseAccountGroup> for AccountGroup {
    fn from(ag: WhitenoiseAccountGroup) -> Self {
        Self {
            id: ag.id,
            account_pubkey: ag.account_pubkey.to_hex(),
            mls_group_id: group_id_to_string(&ag.mls_group_id),
            user_confirmation: ag.user_confirmation,
            created_at: ag.created_at.timestamp_millis(),
            updated_at: ag.updated_at.timestamp_millis(),
        }
    }
}

impl From<&WhitenoiseAccountGroup> for AccountGroup {
    fn from(ag: &WhitenoiseAccountGroup) -> Self {
        Self {
            id: ag.id,
            account_pubkey: ag.account_pubkey.to_hex(),
            mls_group_id: group_id_to_string(&ag.mls_group_id),
            user_confirmation: ag.user_confirmation,
            created_at: ag.created_at.timestamp_millis(),
            updated_at: ag.updated_at.timestamp_millis(),
        }
    }
}

/// Gets all visible AccountGroups for the given account.
/// Visible means: pending or accepted (not declined).
#[frb]
pub async fn visible_account_groups(account_pubkey: String) -> Result<Vec<AccountGroup>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let groups = WhitenoiseAccountGroup::visible_for_account(whitenoise, &pubkey).await?;
    Ok(groups.into_iter().map(|ag| ag.into()).collect())
}

/// Gets all pending AccountGroups for the given account.
/// Pending means the user hasn't yet accepted or declined.
#[frb]
pub async fn pending_account_groups(account_pubkey: String) -> Result<Vec<AccountGroup>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let groups = WhitenoiseAccountGroup::pending_for_account(whitenoise, &pubkey).await?;
    Ok(groups.into_iter().map(|ag| ag.into()).collect())
}

/// Gets a specific AccountGroup by account and group ID.
#[frb]
pub async fn get_account_group(
    account_pubkey: String,
    mls_group_id: String,
) -> Result<Option<AccountGroup>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let group_id_bytes = hex::decode(&mls_group_id)?;
    let group_id = GroupId::from_slice(&group_id_bytes);
    let ag = WhitenoiseAccountGroup::get(whitenoise, &pubkey, &group_id).await?;
    Ok(ag.map(|a| a.into()))
}

/// Accepts a group invite by setting user_confirmation to true.
/// The group will remain visible in the UI.
#[frb]
pub async fn accept_account_group(
    account_pubkey: String,
    mls_group_id: String,
) -> Result<AccountGroup, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let group_id_bytes = hex::decode(&mls_group_id)?;
    let group_id = GroupId::from_slice(&group_id_bytes);

    let ag = WhitenoiseAccountGroup::get(whitenoise, &pubkey, &group_id)
        .await?
        .ok_or_else(|| ApiError::Other {
            message: "AccountGroup not found".to_string(),
        })?;

    let updated = ag.accept(whitenoise).await?;
    Ok(updated.into())
}

/// Declines a group invite by setting user_confirmation to false.
/// The group will be hidden from the UI but remains in MLS.
#[frb]
pub async fn decline_account_group(
    account_pubkey: String,
    mls_group_id: String,
) -> Result<AccountGroup, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let group_id_bytes = hex::decode(&mls_group_id)?;
    let group_id = GroupId::from_slice(&group_id_bytes);

    let ag = WhitenoiseAccountGroup::get(whitenoise, &pubkey, &group_id)
        .await?
        .ok_or_else(|| ApiError::Other {
            message: "AccountGroup not found".to_string(),
        })?;

    let updated = ag.decline(whitenoise).await?;
    Ok(updated.into())
}

/// Checks if a specific group is pending for the account.
#[frb]
pub async fn is_account_group_pending(
    account_pubkey: String,
    mls_group_id: String,
) -> Result<bool, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let group_id_bytes = hex::decode(&mls_group_id)?;
    let group_id = GroupId::from_slice(&group_id_bytes);

    let ag: Option<WhitenoiseAccountGroup> =
        WhitenoiseAccountGroup::get(whitenoise, &pubkey, &group_id).await?;
    Ok(ag.map(|a| a.is_pending()).unwrap_or(false))
}

/// Checks if a specific group is accepted for the account.
#[frb]
pub async fn is_account_group_accepted(
    account_pubkey: String,
    mls_group_id: String,
) -> Result<bool, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let group_id_bytes = hex::decode(&mls_group_id)?;
    let group_id = GroupId::from_slice(&group_id_bytes);

    let ag: Option<WhitenoiseAccountGroup> =
        WhitenoiseAccountGroup::get(whitenoise, &pubkey, &group_id).await?;
    Ok(ag.map(|a| a.is_accepted()).unwrap_or(false))
}

/// Checks if a specific group is declined (hidden) for the account.
#[frb]
pub async fn is_account_group_declined(
    account_pubkey: String,
    mls_group_id: String,
) -> Result<bool, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let group_id_bytes = hex::decode(&mls_group_id)?;
    let group_id = GroupId::from_slice(&group_id_bytes);

    let ag: Option<WhitenoiseAccountGroup> =
        WhitenoiseAccountGroup::get(whitenoise, &pubkey, &group_id).await?;
    Ok(ag.map(|a| a.is_declined()).unwrap_or(false))
}
