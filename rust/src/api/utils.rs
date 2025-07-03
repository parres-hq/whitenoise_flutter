//! Utility functions and data structures for the Whitenoise secure messaging application.
//!
//! This module provides a bridge between the core Whitenoise Rust library and the Flutter
//! application via flutter_rust_bridge. It includes conversion functions, helper utilities,
//! and Flutter-compatible data structures for seamless integration.
//!
//! # Key Features
//! - Flutter-compatible data structures for configuration and metadata
//! - Public key format conversions (hex ↔ npub)
//! - Relay URL parsing and validation
//! - Core system initialization and data management
//! - Error handling utilities

use flutter_rust_bridge::frb;
use std::collections::BTreeMap;
use std::path::Path;
pub use whitenoise::{
    Metadata, PublicKey, RelayUrl, Tag, Whitenoise, WhitenoiseConfig, WhitenoiseError,
};

/// Flutter-compatible configuration structure that holds directory paths as strings.
///
/// This struct is used to pass configuration data from Flutter to Rust, as flutter_rust_bridge
/// cannot directly handle `Path` types. The paths are converted to proper `Path` objects
/// internally when creating a `WhitenoiseConfig`.
#[derive(Debug, Clone)]
pub struct WhitenoiseConfigData {
    /// Path to the directory where application data will be stored
    pub data_dir: String,
    /// Path to the directory where log files will be written
    pub logs_dir: String,
}

/// Flutter-compatible representation of user metadata following Nostr protocol standards.
///
/// This struct provides a bridge between the core library's `Metadata` type and Flutter's
/// type system. The `custom` field is kept private to avoid flutter_rust_bridge
/// auto-generation issues and is accessed through getter/setter methods.
///
/// # Nostr Metadata Fields
/// Most fields correspond to standard Nostr metadata as defined in NIP-01 and related NIPs.
#[derive(Debug, Clone)]
pub struct MetadataData {
    /// User's name/username
    pub name: Option<String>,
    /// Display name for the user (can be different from name)
    pub display_name: Option<String>,
    /// User's bio/description
    pub about: Option<String>,
    /// URL to user's profile picture
    pub picture: Option<String>,
    /// URL to user's banner image
    pub banner: Option<String>,
    /// User's website URL
    pub website: Option<String>,
    /// NIP-05 identifier for verification (e.g., user@domain.com)
    pub nip05: Option<String>,
    /// Lightning Network LNURL-pay address (deprecated, use lud16 instead)
    pub lud06: Option<String>,
    /// Lightning Network address in newer format
    pub lud16: Option<String>,
    /// Private field for additional custom metadata to avoid Flutter Rust Bridge auto-generation issues
    custom: BTreeMap<String, String>,
}

impl MetadataData {
    /// Retrieves the custom metadata fields as a HashMap.
    ///
    /// This method provides access to the private `custom` field, converting from
    /// `BTreeMap` to `HashMap` for Flutter compatibility.
    ///
    /// # Returns
    /// A HashMap containing all custom key-value pairs
    ///
    /// # Example
    /// ```rust
    /// let metadata = MetadataData { /* ... */ };
    /// let custom_fields = metadata.get_custom();
    /// println!("Custom fields: {:?}", custom_fields);
    /// ```
    pub fn get_custom(&self) -> std::collections::HashMap<String, String> {
        self.custom
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect()
    }

    /// Sets the custom metadata fields from a HashMap.
    ///
    /// This method allows updating the private `custom` field, converting from
    /// `HashMap` to `BTreeMap` internally for consistent ordering.
    ///
    /// # Parameters
    /// * `custom_map` - A HashMap containing custom key-value pairs to store
    ///
    /// # Example
    /// ```rust
    /// let mut metadata = MetadataData { /* ... */ };
    /// let mut custom = HashMap::new();
    /// custom.insert("theme".to_string(), "dark".to_string());
    /// metadata.set_custom(custom);
    /// ```
    pub fn set_custom(&mut self, custom_map: std::collections::HashMap<String, String>) {
        self.custom = custom_map.into_iter().collect();
    }
}

/// Converts a core `Metadata` object to a Flutter-compatible `MetadataData` structure.
///
/// This function handles the conversion of the `custom` field from `BTreeMap<String, serde_json::Value>`
/// to `BTreeMap<String, String>`, converting JSON values to their string representations.
/// Arrays and objects are serialized to JSON strings.
///
/// # Parameters
/// * `metadata` - Reference to a core Metadata object
///
/// # Returns
/// A MetadataData struct with all fields converted for Flutter compatibility
///
/// # Example
/// ```rust
/// let core_metadata = Metadata { /* ... */ };
/// let flutter_metadata = convert_metadata_to_data(&core_metadata);
/// ```
#[frb]
pub fn convert_metadata_to_data(metadata: &Metadata) -> MetadataData {
    // Convert BTreeMap<String, serde_json::Value> to BTreeMap<String, String>
    let custom_string_map = metadata
        .custom
        .iter()
        .map(|(key, value)| {
            let string_value = match value {
                serde_json::Value::String(s) => s.clone(),
                serde_json::Value::Number(n) => n.to_string(),
                serde_json::Value::Bool(b) => b.to_string(),
                serde_json::Value::Null => "null".to_string(),
                _ => value.to_string(), // Arrays and objects become JSON strings
            };
            (key.clone(), string_value)
        })
        .collect();

    MetadataData {
        name: metadata.name.clone(),
        display_name: metadata.display_name.clone(),
        about: metadata.about.clone(),
        picture: metadata.picture.clone(),
        banner: metadata.banner.clone(),
        website: metadata.website.clone(),
        nip05: metadata.nip05.clone(),
        lud06: metadata.lud06.clone(),
        lud16: metadata.lud16.clone(),
        custom: custom_string_map,
    }
}

/// Converts a Flutter-compatible `MetadataData` structure back to a core `Metadata` object.
///
/// This function reverses the conversion performed by `convert_metadata_to_data`,
/// attempting to parse string values back to JSON where possible, falling back to
/// string values when parsing fails.
///
/// # Parameters
/// * `metadata_data` - Reference to a MetadataData struct
///
/// # Returns
/// A core Metadata object suitable for use with the Whitenoise library
///
/// # Example
/// ```rust
/// let flutter_metadata = MetadataData { /* ... */ };
/// let core_metadata = convert_metadata_data_to_metadata(&flutter_metadata);
/// ```
#[frb]
pub fn convert_metadata_data_to_metadata(metadata_data: &MetadataData) -> Metadata {
    // Convert BTreeMap<String, String> back to BTreeMap<String, serde_json::Value>
    let custom_value_map = metadata_data
        .custom
        .iter()
        .map(|(key, value)| {
            // Try to parse as JSON first, fall back to string
            let json_value = serde_json::from_str(value)
                .unwrap_or_else(|_| serde_json::Value::String(value.clone()));
            (key.clone(), json_value)
        })
        .collect();

    Metadata {
        name: metadata_data.name.clone(),
        display_name: metadata_data.display_name.clone(),
        about: metadata_data.about.clone(),
        picture: metadata_data.picture.clone(),
        banner: metadata_data.banner.clone(),
        website: metadata_data.website.clone(),
        nip05: metadata_data.nip05.clone(),
        lud06: metadata_data.lud06.clone(),
        lud16: metadata_data.lud16.clone(),
        custom: custom_value_map,
    }
}

/// Parses a public key from a string representation.
///
/// This function accepts both hexadecimal and npub (bech32) formats for public keys,
/// providing flexibility for different input sources.
///
/// # Parameters
/// * `public_key_string` - String representation of a public key (hex or npub format)
///
/// # Returns
/// * `Ok(PublicKey)` - Successfully parsed public key
/// * `Err(WhitenoiseError)` - If parsing fails due to invalid format
///
/// # Example
/// ```rust
/// // From hex format
/// let pubkey = public_key_from_string("abc123...".to_string())?;
///
/// // From npub format
/// let pubkey = public_key_from_string("npub1...".to_string())?;
/// ```
#[frb]
pub fn public_key_from_string(public_key_string: String) -> Result<PublicKey, WhitenoiseError> {
    PublicKey::parse(&public_key_string).map_err(WhitenoiseError::from)
}

/// Converts a `PublicKey` object to npub (bech32) format.
///
/// The npub format is the human-readable bech32 encoding used in Nostr for public keys,
/// making them easier to share and verify visually.
///
/// # Parameters
/// * `public_key` - Reference to a PublicKey object
///
/// # Returns
/// * `Ok(String)` - npub representation (e.g., "npub1...")
/// * `Err(WhitenoiseError)` - If conversion fails
///
/// # Example
/// ```rust
/// let pubkey = PublicKey::parse("abc123...")?;
/// let npub = npub_from_public_key(&pubkey)?;
/// println!("npub: {}", npub); // npub1...
/// ```
#[frb]
pub fn npub_from_public_key(public_key: &PublicKey) -> Result<String, WhitenoiseError> {
    Whitenoise::npub_from_public_key(public_key)
}

/// Converts a hexadecimal public key string to npub format.
///
/// This is a convenience function that combines parsing and conversion in one step.
///
/// # Parameters
/// * `hex_pubkey` - Hexadecimal string representation of a public key
///
/// # Returns
/// * `Ok(String)` - npub representation
/// * `Err(WhitenoiseError)` - If parsing or conversion fails
///
/// # Example
/// ```rust
/// let npub = npub_from_hex_pubkey("abc123...")?;
/// println!("npub: {}", npub);
/// ```
#[frb]
pub fn npub_from_hex_pubkey(hex_pubkey: &str) -> Result<String, WhitenoiseError> {
    Whitenoise::npub_from_hex_pubkey(hex_pubkey)
}

/// Converts an npub (bech32) public key to hexadecimal format.
///
/// This function is useful when you need the raw hex representation of a public key
/// for cryptographic operations or storage.
///
/// # Parameters
/// * `npub` - npub string representation of a public key (e.g., "npub1...")
///
/// # Returns
/// * `Ok(String)` - Hexadecimal representation
/// * `Err(WhitenoiseError)` - If parsing or conversion fails
///
/// # Example
/// ```rust
/// let hex = hex_pubkey_from_npub("npub1...")?;
/// println!("hex: {}", hex);
/// ```
#[frb]
pub fn hex_pubkey_from_npub(npub: &str) -> Result<String, WhitenoiseError> {
    let pubkey = PublicKey::parse(npub).map_err(WhitenoiseError::from)?;
    Ok(pubkey.to_hex())
}

/// Converts a `PublicKey` object to hexadecimal string format.
///
/// This provides direct access to the hex representation of a PublicKey object.
///
/// # Parameters
/// * `public_key` - Reference to a PublicKey object
///
/// # Returns
/// * `Ok(String)` - Hexadecimal representation
/// * `Err(WhitenoiseError)` - If conversion fails
///
/// # Example
/// ```rust
/// let pubkey = PublicKey::parse("npub1...")?;
/// let hex = hex_pubkey_from_public_key(&pubkey)?;
/// ```
#[frb]
pub fn hex_pubkey_from_public_key(public_key: &PublicKey) -> Result<String, WhitenoiseError> {
    Ok(public_key.to_hex())
}

/// Parses a relay URL from a string.
///
/// This function validates and creates a RelayUrl object from a string,
/// ensuring proper URL format for Nostr relays (typically WebSocket URLs).
///
/// # Parameters
/// * `url` - String representation of a relay URL (e.g., "wss://relay.example.com")
///
/// # Returns
/// * `Ok(RelayUrl)` - Successfully parsed and validated relay URL
/// * `Err(WhitenoiseError)` - If the URL is invalid or malformed
///
/// # Example
/// ```rust
/// let relay = relay_url_from_string("wss://relay.damus.io".to_string())?;
/// ```
#[frb]
pub fn relay_url_from_string(url: String) -> Result<RelayUrl, WhitenoiseError> {
    RelayUrl::parse(&url).map_err(WhitenoiseError::from)
}

/// Converts a `RelayUrl` object to its string representation.
///
/// This function provides the string representation of a relay URL for display
/// or serialization purposes.
///
/// # Parameters
/// * `relay_url` - Reference to a RelayUrl object
///
/// # Returns
/// String representation of the relay URL
///
/// # Example
/// ```rust
/// let relay = RelayUrl::parse("wss://relay.damus.io")?;
/// let url_string = string_from_relay_url(&relay);
/// println!("Relay URL: {}", url_string);
/// ```
#[frb]
pub fn string_from_relay_url(relay_url: &RelayUrl) -> String {
    relay_url.to_string()
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
    WhitenoiseConfig::new(Path::new(&data_dir), Path::new(&logs_dir))
}

/// Converts a `WhitenoiseConfig` object to a Flutter-compatible `WhitenoiseConfigData` structure.
///
/// This function allows Flutter to access configuration data in a compatible format,
/// converting Path objects back to strings.
///
/// # Parameters
/// * `config` - Reference to a WhitenoiseConfig object
///
/// # Returns
/// A WhitenoiseConfigData struct with string representations of the paths
///
/// # Example
/// ```rust
/// let config = WhitenoiseConfig::new(data_path, logs_path);
/// let config_data = convert_config_to_data(&config);
/// ```
pub fn convert_config_to_data(config: &WhitenoiseConfig) -> WhitenoiseConfigData {
    WhitenoiseConfigData {
        data_dir: config.data_dir.to_string_lossy().to_string(),
        logs_dir: config.logs_dir.to_string_lossy().to_string(),
    }
}

/// Creates a `Tag` object from a vector of strings.
///
/// Tags are used in Nostr events for various metadata and references such as
/// mentions, replies, and other event relationships.
///
/// # Parameters
/// * `vec` - Vector of strings representing tag components (e.g., ["p", "pubkey", "relay"])
///
/// # Returns
/// * `Ok(Tag)` - Successfully created tag object
/// * `Err(WhitenoiseError)` - If tag creation fails due to invalid format
///
/// # Example
/// ```rust
/// // Create a "p" tag for mentioning a user
/// let tag = tag_from_vec(vec!["p".to_string(), "pubkey123".to_string()])?;
/// ```
pub fn tag_from_vec(vec: Vec<String>) -> Result<Tag, WhitenoiseError> {
    Tag::parse(vec).map_err(WhitenoiseError::from)
}

/// Converts a `WhitenoiseError` to a human-readable string representation.
///
/// This function provides error information that can be displayed in the Flutter UI,
/// using debug formatting to include detailed error context.
///
/// # Parameters
/// * `error` - Reference to a WhitenoiseError
///
/// # Returns
/// String representation of the error with debug information
///
/// # Example
/// ```rust
/// match some_operation() {
///     Ok(result) => println!("Success: {:?}", result),
///     Err(e) => println!("Error: {}", whitenoise_error_to_string(&e)),
/// }
/// ```
#[frb]
pub fn whitenoise_error_to_string(error: &WhitenoiseError) -> String {
    format!("{error:?}")
}
