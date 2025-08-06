use crate::api::utils::{
    convert_metadata_data_to_metadata, convert_metadata_to_data, MetadataData,
};
use flutter_rust_bridge::frb;
use url::Url;
use whitenoise::RelayUrl;
pub use whitenoise::{Account, AccountSettings, ImageType, PublicKey, Whitenoise, WhitenoiseError};

#[derive(Debug, Clone)]
pub struct AccountData {
    pub pubkey: String,
    pub settings: AccountSettings,
    pub nip65_relays: Vec<RelayUrl>,
    pub inbox_relays: Vec<RelayUrl>,
    pub key_package_relays: Vec<RelayUrl>,
    pub last_synced: u64,
}

// Mirror structs for simple types that can be used directly
#[frb(mirror(AccountSettings))]
#[derive(Debug, Clone)]
pub struct _AccountSettings {
    pub dark_theme: bool,
    pub dev_mode: bool,
    pub lockdown_mode: bool,
}

/// Converts a core `Account` object to a Flutter-compatible `AccountData` structure.
///
/// This function bridges the gap between the core Whitenoise library's Account type
/// and the Flutter-compatible AccountData structure, converting complex types like
/// timestamps and public keys to their string representations.
///
/// # Parameters
/// * `account` - Reference to a core Account object
///
/// # Returns
/// An AccountData struct with all fields converted for Flutter compatibility
#[frb]
pub fn convert_account_to_data(account: &Account) -> AccountData {
    AccountData {
        pubkey: account.pubkey.to_hex(),
        settings: account.settings.clone(),
        nip65_relays: account.nip65_relays.clone().into_iter().collect(),
        inbox_relays: account.inbox_relays.clone().into_iter().collect(),
        key_package_relays: account.key_package_relays.clone().into_iter().collect(),
        last_synced: account.last_synced.as_u64(),
    }
}

/// Retrieves all accounts currently stored and logged into the Whitenoise instance.
///
/// This function fetches all accounts that have been previously logged in and are
/// available in the current Whitenoise instance. Each account is converted to a
/// Flutter-compatible AccountData structure for use in the UI.
///
/// # Returns
/// * `Result<Vec<AccountData>, WhitenoiseError>` - A vector of all available accounts,
///   or an error if the operation fails
///
/// # Errors
/// * Returns `WhitenoiseError` if the Whitenoise instance cannot be accessed or if
///   there's an issue fetching the accounts
#[frb]
pub async fn get_accounts() -> Result<Vec<AccountData>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let accounts = whitenoise.fetch_accounts().await?;
    Ok(accounts.values().map(convert_account_to_data).collect())
}

/// Fetches a specific account by its public key.
///
/// This function retrieves account information for a given public key from the
/// Whitenoise instance and converts it to a Flutter-compatible format.
///
/// # Parameters
/// * `pubkey` - The public key of the account to fetch
///
/// # Returns
/// * `Result<AccountData, WhitenoiseError>` - The account data for the specified
///   public key, or an error if the operation fails
///
/// # Errors
/// * Returns `WhitenoiseError` if the account doesn't exist, the Whitenoise instance
///   cannot be accessed, or if there's an issue fetching the account
#[frb]
pub async fn get_account(pubkey: &PublicKey) -> Result<AccountData, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.get_account(pubkey).await?;
    Ok(convert_account_to_data(&account))
}

/// Creates a new account identity and prepares it for MLS (Messaging Layer Security) messaging.
///
/// This function generates a new cryptographic identity, creates an account, and sets up
/// all necessary components for secure messaging using the MLS protocol. The account will
/// be ready for participation in secure group conversations.
///
/// # Returns
/// * `Result<Account, WhitenoiseError>` - The newly created account with full MLS capabilities,
///   or an error if the creation process fails
///
/// # Errors
/// * Returns `WhitenoiseError` if there's an issue with key generation, MLS setup,
///   or if the Whitenoise instance cannot be accessed
#[frb]
pub async fn create_identity() -> Result<Account, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.create_identity().await
}

/// Authenticates and logs in a user account using their private key.
///
/// This function accepts either a Nostr secret key (nsec) or a hexadecimal private key
/// and attempts to log the user into their account. Once logged in, the account becomes
/// available for messaging and other operations.
///
/// # Parameters
/// * `nsec_or_hex_privkey` - The private key in either nsec (bech32) format or hexadecimal format
///
/// # Returns
/// * `Result<Account, WhitenoiseError>` - The successfully logged-in account,
///   or an error if authentication fails
///
/// # Errors
/// * Returns `WhitenoiseError` if the private key is invalid, malformed, or if there's
///   an issue with the login process
#[frb]
pub async fn login(nsec_or_hex_privkey: String) -> Result<Account, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.login(nsec_or_hex_privkey).await
}

/// Logs out an account identified by its public key.
///
/// This function removes the specified account from the active session, clearing
/// any cached data and ensuring the account is no longer available for operations
/// until logged in again.
///
/// # Parameters
/// * `pubkey` - The public key of the account to log out
///
/// # Returns
/// * `Result<(), WhitenoiseError>` - Success (empty result) or an error if logout fails
///
/// # Errors
/// * Returns `WhitenoiseError` if the account doesn't exist, is not currently logged in,
///   or if there's an issue with the logout process
#[frb]
pub async fn logout(pubkey: &PublicKey) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.logout(pubkey).await
}

/// Exports an account's private key in nsec (Nostr secret key) format.
///
/// This function retrieves and exports the private key for the specified account
/// in the standard Nostr nsec format (bech32 encoding). This is useful for backing up
/// accounts or transferring them to other applications.
///
/// # Parameters
/// * `pubkey` - The public key of the account whose private key should be exported
///
/// # Returns
/// * `Result<String, WhitenoiseError>` - The private key in nsec format,
///   or an error if the export fails
///
/// # Errors
/// * Returns `WhitenoiseError` if the account doesn't exist, cannot be accessed,
///   or if there's an issue with the key export process
///
/// # Security Note
/// The exported private key should be handled securely and never exposed in logs or UI
#[frb]
pub async fn export_account_nsec(pubkey: &PublicKey) -> Result<String, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.get_account(pubkey).await?;
    whitenoise.export_account_nsec(&account).await
}

/// Exports an account's public key in npub (Nostr public key) format.
///
/// This function retrieves and exports the public key for the specified account
/// in the standard Nostr npub format (bech32 encoding). This is the account's
/// public identifier that can be safely shared with others.
///
/// # Parameters
/// * `pubkey` - The public key of the account whose npub should be exported
///
/// # Returns
/// * `Result<String, WhitenoiseError>` - The public key in npub format,
///   or an error if the export fails
///
/// # Errors
/// * Returns `WhitenoiseError` if the account doesn't exist, cannot be accessed,
///   or if there's an issue with the key export process
#[frb]
pub async fn export_account_npub(pubkey: &PublicKey) -> Result<String, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.get_account(pubkey).await?;
    whitenoise.export_account_npub(&account).await
}

/// Retrieves metadata information for a specific account.
///
/// This function fetches the profile metadata (such as display name, about text,
/// profile picture, etc.) associated with the given public key. The metadata
/// is converted to a Flutter-compatible format for use in the UI.
///
/// # Parameters
/// * `pubkey` - The public key of the account whose metadata should be fetched
///
/// # Returns
/// * `Result<Option<MetadataData>, WhitenoiseError>` - The account's metadata if it exists,
///   None if no metadata is found, or an error if the operation fails
///
/// # Errors
/// * Returns `WhitenoiseError` if there's an issue accessing the Whitenoise instance
///   or fetching the metadata from the network
#[frb]
pub async fn fetch_metadata_from(
    nip65_relays: Vec<RelayUrl>,
    pubkey: PublicKey,
) -> Result<Option<MetadataData>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let metadata = whitenoise
        .fetch_metadata_from(nip65_relays.into_iter().collect(), pubkey)
        .await?;
    Ok(metadata.map(|m| convert_metadata_to_data(&m)))
}

/// Updates the metadata for a specific account.
///
/// This function publishes updated profile metadata (display name, about text,
/// profile picture, etc.) for the specified account to the Nostr network.
/// The metadata will be broadcast to relays and become available to other users.
///
/// # Parameters
/// * `metadata` - The new metadata to publish for the account
/// * `pubkey` - The public key of the account whose metadata should be updated
///
/// # Returns
/// * `Result<(), WhitenoiseError>` - Success (empty result) or an error if the update fails
///
/// # Errors
/// * Returns `WhitenoiseError` if the account doesn't exist, cannot be accessed,
///   or if there's an issue publishing the metadata to the network
#[frb]
pub async fn update_metadata(
    metadata: &MetadataData,
    pubkey: &PublicKey,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.get_account(pubkey).await?;
    // Convert MetadataData back to Metadata for the whitenoise API
    let metadata_to_save = convert_metadata_data_to_metadata(metadata);
    whitenoise
        .update_metadata(&metadata_to_save, &account)
        .await
}

/// Uploads a profile picture for a specific account to a media server.
///
/// This function takes a local image file and uploads it to the specified media server,
/// making it available as a profile picture for the account. The function supports
/// different image types and returns the URL where the uploaded image can be accessed.
///
/// # Parameters
/// * `pubkey` - The public key of the account whose profile picture should be updated
/// * `server_url` - The URL string of the media server where the image will be uploaded
/// * `file_path` - The local path to the image file that should be uploaded
/// * `image_type` - The type of image being uploaded (e.g., avatar, banner)
///
/// # Returns
/// * `Result<String, WhitenoiseError>` - The URL of the uploaded image if successful,
///   or an error if the upload fails
///
/// # Errors
/// * Returns `WhitenoiseError` if the file cannot be read, the server is unreachable,
///   the upload fails, the URL is invalid, or if there's an issue with the account access
#[frb]
pub async fn upload_profile_picture(
    pubkey: PublicKey,
    server_url: String,
    file_path: &str,
    image_type: ImageType,
) -> Result<String, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;

    // Parse the server URL string into a Url
    let server =
        Url::parse(&server_url).map_err(|e| WhitenoiseError::from(std::io::Error::other(e)))?;

    whitenoise
        .upload_profile_picture(pubkey, server, file_path, image_type)
        .await
}
