use crate::api::{error::ApiError, utils::group_id_to_string};
use flutter_rust_bridge::frb;
use nostr_mls::prelude::welcome_types::Welcome as WhitenoiseWelcome;
use nostr_mls::prelude::welcome_types::WelcomeState as WhitenoiseWelcomeState;
use nostr_sdk::prelude::*;
use whitenoise::Whitenoise;

/// Converts a GroupId to a hex string representation.
///
/// This function provides a consistent way to convert MLS group IDs to strings
/// for use in the Flutter bridge layer.
///
/// # Parameters
/// * `group_id` - Reference to a GroupId object
///
/// # Returns
/// Hexadecimal string representation of the group ID

#[frb]
#[derive(Debug, Clone)]
pub struct Welcome {
    pub id: String,
    pub mls_group_id: String,
    pub nostr_group_id: String,
    pub group_name: String,
    pub group_description: String,
    pub group_admin_pubkeys: Vec<String>,
    pub group_relays: Vec<String>,
    pub welcomer: String,
    pub member_count: u32,
    pub state: WelcomeState,
    pub created_at: u64,
}

#[frb]
#[derive(Debug, Clone)]
pub enum WelcomeState {
    // Pending: The welcome has been sent but not yet accepted or declined
    Pending,
    // Accepted: The welcome has been accepted
    Accepted,
    // Declined: The welcome has been declined
    Declined,
    // Ignored: The welcome has been ignored
    Ignored,
}

impl From<WhitenoiseWelcomeState> for WelcomeState {
    fn from(state: WhitenoiseWelcomeState) -> Self {
        match state {
            WhitenoiseWelcomeState::Pending => WelcomeState::Pending,
            WhitenoiseWelcomeState::Accepted => WelcomeState::Accepted,
            WhitenoiseWelcomeState::Declined => WelcomeState::Declined,
            WhitenoiseWelcomeState::Ignored => WelcomeState::Ignored,
        }
    }
}

impl From<WhitenoiseWelcome> for Welcome {
    fn from(welcome: WhitenoiseWelcome) -> Self {
        Self {
            id: welcome.id.to_string(),
            mls_group_id: group_id_to_string(&welcome.mls_group_id),
            nostr_group_id: hex::encode(welcome.nostr_group_id),
            group_name: welcome.group_name,
            group_description: welcome.group_description,
            group_admin_pubkeys: welcome
                .group_admin_pubkeys
                .iter()
                .map(|pk| pk.to_hex())
                .collect(),
            group_relays: welcome.group_relays.iter().map(|r| r.to_string()).collect(),
            welcomer: welcome.welcomer.to_hex(),
            member_count: welcome.member_count,
            state: welcome.state.into(),
            created_at: welcome.event.created_at.as_u64(),
        }
    }
}

impl From<&WhitenoiseWelcome> for Welcome {
    fn from(welcome: &WhitenoiseWelcome) -> Self {
        Self {
            id: welcome.id.to_string(),
            mls_group_id: group_id_to_string(&welcome.mls_group_id),
            nostr_group_id: hex::encode(welcome.nostr_group_id),
            group_name: welcome.group_name.clone(),
            group_description: welcome.group_description.clone(),
            group_admin_pubkeys: welcome
                .group_admin_pubkeys
                .iter()
                .map(|pk| pk.to_hex())
                .collect(),
            group_relays: welcome.group_relays.iter().map(|r| r.to_string()).collect(),
            welcomer: welcome.welcomer.to_hex(),
            member_count: welcome.member_count,
            state: welcome.state.into(),
            created_at: welcome.event.created_at.as_u64(),
        }
    }
}

#[frb]
pub async fn pending_welcomes(pubkey: String) -> Result<Vec<Welcome>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let welcomes = whitenoise.pending_welcomes(&pubkey).await?;
    Ok(welcomes.into_iter().map(|w| w.into()).collect())
}

#[frb]
pub async fn find_welcome_by_event_id(
    pubkey: String,
    welcome_event_id: String,
) -> Result<Welcome, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    let welcome = whitenoise
        .find_welcome_by_event_id(&pubkey, welcome_event_id)
        .await?;
    Ok(welcome.into())
}

#[frb]
pub async fn accept_welcome(pubkey: String, welcome_event_id: String) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    whitenoise
        .accept_welcome(&pubkey, welcome_event_id)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn decline_welcome(pubkey: String, welcome_event_id: String) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::from_hex(&pubkey)?;
    whitenoise
        .decline_welcome(&pubkey, welcome_event_id)
        .await
        .map_err(ApiError::from)
}
