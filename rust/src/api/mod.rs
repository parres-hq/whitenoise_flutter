// Re-export everything from the whitenoise crate
use flutter_rust_bridge::frb;
pub use whitenoise::{
    Account, AccountSettings, Event, Group, GroupId, GroupState, GroupType, Kind,
    MessageWithTokens, Metadata, OnboardingState, PublicKey, RelayType, RelayUrl, Tag, Whitenoise,
    WhitenoiseConfig, WhitenoiseError,
};

// Declare the modules
pub mod accounts;
pub mod contacts;
pub mod groups;
pub mod messages;
pub mod relays;
pub mod utils;

// Re-export everything
pub use accounts::*;
pub use contacts::*;
pub use groups::*;
pub use messages::*;
pub use relays::*;
pub use utils::*;

/// Initializes the Whitenoise system with the provided configuration.
///
/// # CRITICAL: Must be called first
/// This function MUST be called before any other Whitenoise methods are used.
/// It sets up the global singleton instance, creates necessary directories,
/// and initializes the database connections.
///
/// # Parameters
/// * `config` - WhitenoiseConfig object containing setup parameters
///
/// # Returns
/// * `Ok(())` - System successfully initialized
/// * `Err(WhitenoiseError)` - If initialization fails (directory creation, database setup, etc.)
///
/// # Example
/// ```rust
/// let config = create_whitenoise_config(
///     "/app/data".to_string(),
///     "/app/logs".to_string()
/// );
/// initialize_whitenoise(config).await?;
///
/// // Now other Whitenoise functions can be called
/// ```
///
/// # Errors
/// Common failure reasons:
/// - Insufficient permissions to create directories
/// - Database corruption or locking issues
/// - Invalid configuration parameters
#[frb]
pub async fn initialize_whitenoise(config: WhitenoiseConfig) -> Result<(), WhitenoiseError> {
    Whitenoise::initialize_whitenoise(config).await
}

/// Deletes all data from the Whitenoise instance.
///
/// # WARNING: This action is irreversible
/// This function logs out all accounts and removes ALL local data from the application.
/// Use with extreme caution as this cannot be undone.
///
/// # Returns
/// * `Ok(())` - All data successfully deleted
/// * `Err(WhitenoiseError)` - If deletion fails or instance not initialized
///
/// # Usage
/// Typically used for:
/// - Factory reset functionality
/// - Complete app data cleanup during uninstall
/// - Development/testing purposes
/// - Recovery from corrupted state
///
/// # Example
/// ```rust
/// // Confirm with user before calling this
/// if user_confirmed_reset {
///     delete_all_data().await?;
///     println!("All data has been deleted");
/// }
/// ```
///
/// # Errors
/// Common failure reasons:
/// - Whitenoise not initialized
/// - File system permission issues
/// - Database locks or corruption
#[frb]
pub async fn delete_all_data() -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.delete_all_data().await
}
