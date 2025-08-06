use flutter_rust_bridge::frb;
pub use whitenoise::{
    Event, PublicKey, RelayStatus, RelayType, RelayUrl, Whitenoise, WhitenoiseError,
};

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
pub async fn fetch_relays_from(
    nip65_relays: Vec<RelayUrl>,
    pubkey: PublicKey,
    relay_type: RelayType,
) -> Result<Vec<RelayUrl>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise
        .fetch_relays_from(nip65_relays.into_iter().collect(), pubkey, relay_type)
        .await.map(|set| set.into_iter().collect())
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
pub async fn fetch_key_package(
    pubkey: PublicKey,
    nip65_relays: Vec<RelayUrl>,
) -> Result<Option<Event>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let key_package_relays = whitenoise
        .fetch_relays_from(nip65_relays.clone().into_iter().collect(), pubkey, RelayType::KeyPackage)
        .await?;
    if key_package_relays.is_empty() {
        return Ok(None);
    }
    whitenoise
        .fetch_key_package_event_from(key_package_relays, pubkey)
        .await
}

/// Fetches the connection status of all relays associated with an account.
///
/// This function retrieves the current connection status for all relay URLs
/// configured across all relay types (Nostr, Inbox, and KeyPackage) for the
/// specified account. This is useful for monitoring relay connectivity and
/// diagnosing connection issues. Both relay URLs and statuses are converted
/// to string format for Flutter compatibility.
///
/// # Parameters
/// * `pubkey` - The public key of the account whose relay statuses to check
///
/// # Returns
/// * `Ok(Vec<(String, String)>)` - Vector of tuples containing each relay URL as a string and its current status as a string
/// * `Err(WhitenoiseError)` - If there was an error fetching relay statuses or account not found
///
/// # Notes
/// * The status reflects the current connection state at the time of the call
/// * Relay statuses can change frequently due to network conditions
/// * This function checks all relay types configured for the account
/// * Possible status values include: "Initialized", "Pending", "Connecting", "Connected", "Disconnected", "Terminated", "Banned", "Sleeping"
///
/// # Example
/// ```rust
/// let statuses = fetch_relay_status(pubkey).await?;
/// for (url, status) in statuses {
///     println!("Relay {} is {}", url, status);
/// }
/// ```
#[frb]
pub async fn fetch_relay_status(
    pubkey: PublicKey,
) -> Result<Vec<(String, String)>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.get_account(&pubkey).await?;
    let statuses = whitenoise.fetch_relay_status(&account).await?;
    let converted_statuses = statuses
        .into_iter()
        .map(|(url, status)| (url.to_string(), status.to_string()))
        .collect();
    Ok(converted_statuses)
}
