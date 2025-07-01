use flutter_rust_bridge::frb;
pub use whitenoise::{Event, PublicKey, RelayType, RelayUrl, Whitenoise, WhitenoiseError};

/// Creates a RelayType::Nostr variant.
///
/// This helper function returns the Nostr relay type, used for general
/// Nostr protocol communication and event publishing/subscription.
///
/// # Returns
/// RelayType::Nostr variant
#[frb]
pub fn relay_type_nostr() -> RelayType {
    RelayType::Nostr
}

/// Creates a RelayType::Inbox variant.
///
/// This helper function returns the Inbox relay type, used specifically
/// for receiving private messages and notifications in the Whitenoise protocol.
///
/// # Returns
/// RelayType::Inbox variant
#[frb]
pub fn relay_type_inbox() -> RelayType {
    RelayType::Inbox
}

/// Creates a RelayType::KeyPackage variant.
///
/// This helper function returns the KeyPackage relay type, used for
/// publishing and retrieving MLS key packages required for group membership.
///
/// # Returns
/// RelayType::KeyPackage variant
#[frb]
pub fn relay_type_key_package() -> RelayType {
    RelayType::KeyPackage
}

/// Fetches all relays of a specific type associated with an account.
///
/// This function retrieves the relay URLs configured for a specific account
/// and relay type. Different relay types serve different purposes in the
/// Whitenoise protocol (Nostr events, inbox messages, key packages).
///
/// # Parameters
/// * `pubkey` - The public key of the account whose relays to fetch
/// * `relay_type` - The type of relays to retrieve (Nostr, Inbox, or KeyPackage)
///
/// # Returns
/// * `Ok(Vec<RelayUrl>)` - Vector of relay URLs for the specified type
/// * `Err(WhitenoiseError)` - If there was an error fetching relays or account not found
#[frb]
pub async fn fetch_relays(
    pubkey: PublicKey,
    relay_type: RelayType,
) -> Result<Vec<RelayUrl>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.fetch_relays(pubkey, relay_type).await
}

/// Updates an account's relay list for a specific relay type.
///
/// This function replaces the entire relay list for the specified type with
/// the provided URLs. The changes will be persisted and synchronized.
///
/// # Parameters
/// * `pubkey` - The public key of the account whose relays to update
/// * `relay_type` - The type of relays to update (Nostr, Inbox, or KeyPackage)
/// * `relays` - Vector of relay URLs to set for this type
///
/// # Returns
/// * `Ok(())` - If the relays were successfully updated
/// * `Err(WhitenoiseError)` - If there was an error updating relays
///
/// # Notes
/// * This operation completely replaces the existing relay list for the specified type
/// * At least one relay of each type is typically required for proper functionality
#[frb]
pub async fn update_relays(
    pubkey: &PublicKey,
    relay_type: RelayType,
    relays: Vec<RelayUrl>,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.update_relays(&account, relay_type, relays).await
}

/// Fetches an account's MLS key package from its configured key package relays.
///
/// This function retrieves the key package event for the specified account from
/// its key package relays. Key packages are required for adding users to MLS groups
/// and must be available on relays for group membership to work.
///
/// # Parameters
/// * `pubkey` - The public key of the account whose key package to fetch
///
/// # Returns
/// * `Ok(Some(Event))` - The key package event if found
/// * `Ok(None)` - If no key package was found on the relays
/// * `Err(WhitenoiseError)` - If there was an error fetching the key package
///
/// # Notes
/// * This function automatically uses the account's configured key package relays
/// * Key packages have expiration times and may need to be refreshed periodically
#[frb]
pub async fn fetch_key_package(pubkey: PublicKey) -> Result<Option<Event>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let relays = whitenoise
        .fetch_relays(pubkey, RelayType::KeyPackage)
        .await?;
    whitenoise.fetch_key_package_event(pubkey, relays).await
}
