pub mod accounts;

use whitenoise::*;

#[flutter_rust_bridge::frb(sync)]
pub async fn initialize_whitenoise(config: WhitenoiseConfig) -> Result<Whitenoise, WhitenoiseError> {
    Whitenoise::initialize_whitenoise(config).await
}
