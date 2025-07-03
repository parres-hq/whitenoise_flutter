use crate::api::groups::group_id_to_string;
use flutter_rust_bridge::frb;
pub use whitenoise::{PublicKey, Welcome, WelcomeState, Whitenoise, WhitenoiseError};

#[derive(Debug, Clone)]
pub struct WelcomeData {
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
}

#[frb(mirror(WelcomeState))]
#[derive(Debug, Clone)]
pub enum _WelcomeState {
    // Pending: The welcome has been sent but not yet accepted or declined
    Pending,
    // Accepted: The welcome has been accepted
    Accepted,
    // Declined: The welcome has been declined
    Declined,
    // Ignored: The welcome has been ignored
    Ignored,
}

pub fn convert_welcome_to_data(welcome: &Welcome) -> WelcomeData {
    WelcomeData {
        id: welcome.id.to_string(),
        mls_group_id: group_id_to_string(&welcome.mls_group_id),
        nostr_group_id: hex::encode(welcome.nostr_group_id),
        group_name: welcome.group_name.to_string(),
        group_description: welcome.group_description.to_string(),
        group_admin_pubkeys: welcome
            .group_admin_pubkeys
            .iter()
            .map(|pk| pk.to_hex())
            .collect(),
        group_relays: welcome.group_relays.iter().map(|r| r.to_string()).collect(),
        welcomer: welcome.welcomer.to_hex(),
        member_count: welcome.member_count,
        state: welcome.state,
    }
}

/// Fetches all welcome invitations for a given public key.
///
/// Welcome invitations are group membership invitations that have been sent to the user
/// but may not yet have been processed (accepted, declined, or ignored).
///
/// # Arguments
///
/// * `pubkey` - The public key of the account to fetch welcomes for
///
/// # Returns
///
/// Returns a `Result` containing:
/// * `Ok(Vec<WelcomeData>)` - A vector of welcome invitation data if successful
/// * `Err(WhitenoiseError)` - An error if the operation fails
///
/// # Errors
///
/// This function will return an error if:
/// * The Whitenoise instance cannot be retrieved
/// * The network request to fetch welcomes fails
/// * The account associated with the public key is not found
#[frb]
pub async fn fetch_welcomes(pubkey: &PublicKey) -> Result<Vec<WelcomeData>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let welcomes = whitenoise.fetch_welcomes(pubkey).await?;
    Ok(welcomes.iter().map(convert_welcome_to_data).collect())
}

/// Fetches a specific welcome invitation by its event ID.
///
/// This method retrieves detailed information about a single welcome invitation,
/// including group details, admin information, and current state.
///
/// # Arguments
///
/// * `pubkey` - The public key of the account that received the welcome
/// * `welcome_event_id` - The unique event ID of the welcome invitation to fetch
///
/// # Returns
///
/// Returns a `Result` containing:
/// * `Ok(WelcomeData)` - The welcome invitation data if found
/// * `Err(WhitenoiseError)` - An error if the operation fails
///
/// # Errors
///
/// This function will return an error if:
/// * The Whitenoise instance cannot be retrieved
/// * The welcome with the specified event ID is not found
/// * The account associated with the public key is not found
/// * Network connectivity issues occur
#[frb]
pub async fn fetch_welcome(
    pubkey: &PublicKey,
    welcome_event_id: String,
) -> Result<WelcomeData, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let welcome = whitenoise.fetch_welcome(pubkey, welcome_event_id).await?;
    Ok(convert_welcome_to_data(&welcome))
}

/// Accepts a group welcome invitation.
///
/// This method processes a welcome invitation by accepting it, which typically involves:
/// * Joining the MLS group
/// * Updating the welcome state to "Accepted"
/// * Synchronizing with the group's message history
///
/// # Arguments
///
/// * `pubkey` - The public key of the account accepting the welcome
/// * `welcome_event_id` - The unique event ID of the welcome invitation to accept
///
/// # Returns
///
/// Returns a `Result` containing:
/// * `Ok(())` - Success indicator if the welcome was accepted
/// * `Err(WhitenoiseError)` - An error if the operation fails
///
/// # Errors
///
/// This function will return an error if:
/// * The Whitenoise instance cannot be retrieved
/// * The account associated with the public key is not found
/// * The welcome with the specified event ID is not found
/// * The welcome has already been processed (accepted/declined)
/// * MLS group joining fails
/// * Network connectivity issues occur
#[frb]
pub async fn accept_welcome(
    pubkey: &PublicKey,
    welcome_event_id: String,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.accept_welcome(pubkey, welcome_event_id).await
}

/// Declines a group welcome invitation.
///
/// This method processes a welcome invitation by declining it, which:
/// * Updates the welcome state to "Declined"
/// * Prevents the user from joining the associated group
/// * May send a decline notification to the group admin (implementation dependent)
///
/// # Arguments
///
/// * `pubkey` - The public key of the account declining the welcome
/// * `welcome_event_id` - The unique event ID of the welcome invitation to decline
///
/// # Returns
///
/// Returns a `Result` containing:
/// * `Ok(())` - Success indicator if the welcome was declined
/// * `Err(WhitenoiseError)` - An error if the operation fails
///
/// # Errors
///
/// This function will return an error if:
/// * The Whitenoise instance cannot be retrieved
/// * The account associated with the public key is not found
/// * The welcome with the specified event ID is not found
/// * The welcome has already been processed (accepted/declined)
/// * Network connectivity issues occur
#[frb]
pub async fn decline_welcome(
    pubkey: &PublicKey,
    welcome_event_id: String,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.decline_welcome(pubkey, welcome_event_id).await
}
