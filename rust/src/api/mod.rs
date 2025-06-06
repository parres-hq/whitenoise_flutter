pub mod accounts;

// Re-export everything from the whitenoise crate
pub use whitenoise::*;

use std::path::Path;

// Helper function to create a WhitenoiseConfig from String paths (since Dart can't pass &Path directly)
pub fn create_whitenoise_config(data_dir: String, logs_dir: String) -> WhitenoiseConfig {
    WhitenoiseConfig::new(Path::new(&data_dir), Path::new(&logs_dir))
}

// Wrapper for Whitenoise::initialize_whitenoise to make it available to Dart
pub async fn initialize_whitenoise(config: WhitenoiseConfig) -> Result<Whitenoise, WhitenoiseError> {
    Whitenoise::initialize_whitenoise(config).await
}
