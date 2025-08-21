//! Utility functions and data structures for White Noise API.
//!
//! This module provides essential utility functions for the White Noise Flutter application,
//! including key management, relay operations, and data conversions.

use flutter_rust_bridge::frb;
pub use whitenoise::{
    GroupId, PublicKey, RelayUrl, Tag, Whitenoise, WhitenoiseError,
};

#[frb]
pub fn npub_from_public_key(public_key: &PublicKey) -> Result<String, WhitenoiseError> {
    Whitenoise::npub_from_public_key(public_key)
}

#[frb]
pub fn npub_from_hex_pubkey(hex_pubkey: &str) -> Result<String, WhitenoiseError> {
    Whitenoise::npub_from_hex_pubkey(hex_pubkey)
}

#[frb]
pub fn hex_pubkey_from_npub(npub: &str) -> Result<String, WhitenoiseError> {
    let pubkey = PublicKey::parse(npub).map_err(WhitenoiseError::from)?;
    Ok(pubkey.to_hex())
}

#[frb]
pub fn hex_pubkey_from_public_key(public_key: &PublicKey) -> Result<String, WhitenoiseError> {
    Ok(public_key.to_hex())
}

#[frb]
pub fn relay_url_from_string(url: String) -> Result<RelayUrl, WhitenoiseError> {
    RelayUrl::parse(&url).map_err(WhitenoiseError::from)
}

#[frb]
pub fn string_from_relay_url(relay_url: &RelayUrl) -> String {
    relay_url.to_string()
}

pub fn tag_from_vec(vec: Vec<String>) -> Result<Tag, WhitenoiseError> {
    Tag::parse(vec).map_err(WhitenoiseError::from)
}

#[frb]
pub fn whitenoise_error_to_string(error: &WhitenoiseError) -> String {
    format!("{error:?}")
}

#[frb]
pub fn get_default_blossom_server_url() -> String {
    #[cfg(debug_assertions)]
    {
        "http://localhost:7777".to_string()
    }
    #[cfg(not(debug_assertions))]
    {
        "https://uploads.primal.net".to_string()
    }
}

pub fn group_id_to_string(group_id: &GroupId) -> String {
    hex::encode(group_id.as_slice())
}

pub fn group_id_from_string(group_id: &str) -> Result<GroupId, WhitenoiseError> {
    let bytes = hex::decode(group_id).map_err(|e| WhitenoiseError::Other(anyhow::Error::from(e)))?;
    Ok(GroupId::from_slice(&bytes))
}
