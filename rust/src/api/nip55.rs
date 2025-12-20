use crate::api::accounts::Account;
use crate::api::error::ApiError;
use flutter_rust_bridge::{DartFnFuture, frb};
use nostr_sdk::prelude::*;
use std::sync::Arc;
use whitenoise::Whitenoise;
use whitenoise::whitenoise::nip55_signer::Nip55FlutterCallback;

pub struct FlutterNip55Callback {
    callback: Arc<dyn Fn(String, String) -> DartFnFuture<String> + Send + Sync>,
}

impl std::fmt::Debug for FlutterNip55Callback {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "FlutterNip55Callback")
    }
}

impl Nip55FlutterCallback for FlutterNip55Callback {
    fn call_nip55_method(
        &self,
        method: &str,
        params: &str,
    ) -> std::result::Result<std::string::String, std::string::String> {
        let future = (self.callback)(method.to_string(), params.to_string());

        Ok(tokio::task::block_in_place(|| {
            tokio::runtime::Handle::current().block_on(future)
        }))
    }
}

/// Set the NIP-55 Flutter callback for handling external signer requests
///
/// This callback will be invoked by the Rust core when it needs to delegate
/// signing operations to an external Android signer app.
#[frb]
pub async fn set_nip55_flutter_callback(
    callback: impl Fn(String, String) -> DartFnFuture<String> + Send + Sync + 'static,
) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;

    // Create the callback implementation
    let nip55_callback = Arc::new(FlutterNip55Callback {
        callback: Arc::new(callback),
    });

    // Set the callback in the Whitenoise instance
    whitenoise.set_nip55_flutter_callback(nip55_callback).await;
    Ok(())
}

/// Login with NIP-55 external signer
///
/// This method retrieves the public key from the external signer,
/// creates or finds the account, enables the NIP-55 signer, and sets up relays.
#[frb]
pub async fn login_with_nip55() -> Result<Account, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.login_with_nip55().await?;
    Ok(account.into())
}

/// Enable NIP-55 external signer for a specific account
///
/// When enabled, signing operations for this account will be delegated
/// to the external Android signer app instead of using the local key.
///
/// NOTE: This requires the account to already exist. Use `login_with_nip55`
/// for initial account creation/login.
#[frb]
pub async fn enable_nip55_signer(pubkey: String) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;

    // Find the account first
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;

    // Enable NIP55 signer - this should persist the setting so future operations use the signer
    whitenoise.enable_nip55_signer(&account).await.map_err(|e| {
        // Log the error for debugging
        eprintln!(
            "Failed to enable NIP55 signer for account {}: {:?}",
            pubkey.to_hex(),
            e
        );
        ApiError::from(e)
    })
}

/// Disable NIP-55 external signer for a specific account
///
/// When disabled, signing operations will use the local key again.
#[frb]
pub async fn disable_nip55_signer(pubkey: String) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&pubkey)?;

    // Find the account first
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;

    whitenoise.disable_nip55_signer(&account).await;
    Ok(())
}
