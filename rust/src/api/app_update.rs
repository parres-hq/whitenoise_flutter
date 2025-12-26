use crate::api::error::ApiError;
use flutter_rust_bridge::frb;
use whitenoise::{
    AppUpdateInfo as WhitenoiseAppUpdateInfo, check_for_app_update as wn_check_for_app_update,
};

/// Information about available application updates.
///
/// This struct contains details about the latest available version
/// and whether an update is available compared to the current version.
#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct AppUpdateInfo {
    /// The latest available version string (e.g., "1.2.3")
    pub version: String,
    /// Whether an update is available (true if latest > current)
    pub update_available: bool,
}

impl From<WhitenoiseAppUpdateInfo> for AppUpdateInfo {
    fn from(info: WhitenoiseAppUpdateInfo) -> Self {
        Self {
            version: info.version,
            update_available: info.update_available,
        }
    }
}

/// Checks for available application updates.
///
/// This function queries the Zapstore relay to fetch the latest version
/// information for Whitenoise and compares it against the provided current version.
///
/// # Parameters
/// * `current_version` - The current application version string in semver format (e.g., "1.2.3")
///
/// # Returns
/// An `AppUpdateInfo` containing the latest version and whether an update is available.
///
/// # Errors
/// Returns an error if:
/// - Failed to connect to the Zapstore relay
/// - No version events were found
/// - The version string format is invalid
#[frb]
pub async fn check_for_app_update(current_version: String) -> Result<AppUpdateInfo, ApiError> {
    let info = wn_check_for_app_update(&current_version)
        .await
        .map_err(ApiError::from)?;
    Ok(AppUpdateInfo::from(info))
}
