// Re-export everything from the whitenoise crate
use flutter_rust_bridge::frb;
use std::path::Path;
pub use whitenoise::{
    AppSettings, Event, GroupId, GroupState, GroupType, Kind, MessageWithTokens, PublicKey,
    RelayType, RelayUrl, Tag, ThemeMode, Whitenoise, WhitenoiseError,
};

/// Flutter-compatible configuration structure that holds directory paths as strings.
///
/// This struct is used to pass configuration data from Flutter to Rust, as flutter_rust_bridge
/// cannot directly handle `Path` types. The paths are converted to proper `Path` objects
/// internally when creating a `WhitenoiseConfig`.
#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct WhitenoiseConfig {
    /// Path to the directory where application data will be stored
    pub data_dir: String,
    /// Path to the directory where log files will be written
    pub logs_dir: String,
}

impl From<whitenoise::WhitenoiseConfig> for WhitenoiseConfig {
    fn from(config: whitenoise::WhitenoiseConfig) -> Self {
        Self {
            data_dir: config.data_dir.to_string_lossy().to_string(),
            logs_dir: config.logs_dir.to_string_lossy().to_string(),
        }
    }
}

/// Creates a `WhitenoiseConfig` object from string directory paths.
///
/// This function bridges the gap between Flutter's string-based paths and Rust's
/// `Path` types, creating a proper configuration object for Whitenoise initialization.
///
/// # Parameters
/// * `data_dir` - Path string for data directory where app data will be stored
/// * `logs_dir` - Path string for logs directory where log files will be written
///
/// # Returns
/// A WhitenoiseConfig object ready for initialization
///
/// # Example
/// ```rust
/// let config = create_whitenoise_config(
///     "/path/to/data".to_string(),
///     "/path/to/logs".to_string()
/// );
/// ```
#[frb]
pub fn create_whitenoise_config(data_dir: String, logs_dir: String) -> WhitenoiseConfig {
    WhitenoiseConfig {
        data_dir,
        logs_dir,
    }
}

// Declare the modules
pub mod accounts;
pub mod groups;
pub mod messages;
pub mod metadata;
pub mod relays;
pub mod users;
pub mod utils;
pub mod welcomes;

// Re-export everything
pub use accounts::*;
pub use groups::*;
pub use messages::*;
pub use metadata::*;
pub use relays::*;
pub use users::*;
pub use utils::*;
pub use welcomes::*;

#[frb]
pub async fn initialize_whitenoise(config: WhitenoiseConfig) -> Result<(), WhitenoiseError> {
    let core_config = whitenoise::WhitenoiseConfig::new(
        Path::new(&config.data_dir),
        Path::new(&config.logs_dir)
    );
    Whitenoise::initialize_whitenoise(core_config).await
}

#[frb]
pub async fn delete_all_data() -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.delete_all_data().await
}

#[frb]
pub async fn get_app_settings() -> Result<AppSettings, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.app_settings().await
}

#[frb]
pub async fn update_theme_mode(theme_mode: ThemeMode) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.update_theme_mode(theme_mode).await
}
