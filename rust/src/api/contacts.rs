use crate::api::utils::{convert_metadata_to_data, MetadataData};
use flutter_rust_bridge::frb;
use std::collections::HashMap;
pub use whitenoise::{PublicKey, Whitenoise, WhitenoiseError};

/// Fetches all contacts associated with an account.
///
/// This function retrieves the complete contact list for a specified account,
/// including metadata information for each contact when available. The contacts
/// are returned as a HashMap where keys are contact public keys and values are
/// optional metadata. This uses the `fetch_contacts` method of the Whitenoise
/// library, which will go to relays to fetch the contacts and their metadata.
///
/// # Parameters
/// * `pubkey` - The public key of the account whose contacts to fetch
///
/// # Returns
/// * `Ok(HashMap<PublicKey, Option<MetadataData>>)` - Map of contact public keys to their metadata
/// * `Err(WhitenoiseError)` - If there was an error fetching contacts or account not found
///
/// # Example
/// ```rust
/// let contacts = fetch_contacts(account_pubkey).await?;
/// println!("Found {} contacts", contacts.len());
/// ```
#[frb]
pub async fn fetch_contacts(
    pubkey: PublicKey,
) -> Result<HashMap<PublicKey, Option<MetadataData>>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let contacts = whitenoise.fetch_contacts(pubkey).await?;
    let converted_contacts = contacts
        .into_iter()
        .map(|(pk, metadata_opt)| {
            let converted_metadata = metadata_opt.map(|m| convert_metadata_to_data(&m));
            (pk, converted_metadata)
        })
        .collect();
    Ok(converted_contacts)
}

/// Queries all contacts associated with an account.
///
/// This function retrieves the complete contact list for a specified account,
/// including metadata information for each contact when available. The contacts
/// are returned as a HashMap where keys are contact public keys and values are
/// optional metadata. This uses the `query_contacts` method of the Whitenoise
/// library, which just hits the local nostr database cache to fetch the contacts and their metadata.
///
/// # Parameters
/// * `pubkey` - The public key of the account whose contacts to fetch
///
/// # Returns
/// * `Ok(HashMap<PublicKey, Option<MetadataData>>)` - Map of contact public keys to their metadata
/// * `Err(WhitenoiseError)` - If there was an error fetching contacts or account not found
///
/// # Example
/// ```rust
/// let contacts = fetch_contacts(account_pubkey).await?;
/// println!("Found {} contacts", contacts.len());
/// ```
#[frb]
pub async fn query_contacts(
    pubkey: PublicKey,
) -> Result<HashMap<PublicKey, Option<MetadataData>>, WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let contacts = whitenoise.query_contacts(pubkey).await?;
    let converted_contacts = contacts
        .into_iter()
        .map(|(pk, metadata_opt)| {
            let converted_metadata = metadata_opt.map(|m| convert_metadata_to_data(&m));
            (pk, converted_metadata)
        })
        .collect();
    Ok(converted_contacts)
}
/// Adds a new contact to an account's contact list.
///
/// This function adds the specified contact public key to the account's contact list.
/// The contact will be persisted and synchronized across the account's relays.
///
/// # Parameters
/// * `pubkey` - The public key of the account to add the contact to
/// * `contact_pubkey` - The public key of the contact to add
///
/// # Returns
/// * `Ok(())` - If the contact was successfully added
/// * `Err(WhitenoiseError)` - If there was an error adding the contact (e.g., account not found, network error)
///
/// # Example
/// ```rust
/// add_contact(&my_pubkey, contact_pubkey).await?;
/// println!("Contact added successfully");
/// ```
#[frb]
pub async fn add_contact(
    pubkey: &PublicKey,
    contact_pubkey: PublicKey,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.add_contact(&account, contact_pubkey).await
}

/// Removes a contact from an account's contact list.
///
/// This function removes the specified contact public key from the account's contact list.
/// The change will be persisted and synchronized across the account's relays.
///
/// # Parameters
/// * `pubkey` - The public key of the account to remove the contact from
/// * `contact_pubkey` - The public key of the contact to remove
///
/// # Returns
/// * `Ok(())` - If the contact was successfully removed
/// * `Err(WhitenoiseError)` - If there was an error removing the contact (e.g., account not found, contact not in list)
///
/// # Example
/// ```rust
/// remove_contact(&my_pubkey, unwanted_contact).await?;
/// println!("Contact removed successfully");
/// ```
#[frb]
pub async fn remove_contact(
    pubkey: &PublicKey,
    contact_pubkey: PublicKey,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.remove_contact(&account, contact_pubkey).await
}

/// Completely replaces an account's contact list with a new set of contacts.
///
/// This function overwrites the entire contact list with the provided public keys.
/// This is useful for bulk updates or synchronization operations. All existing
/// contacts not in the new list will be removed.
///
/// # Parameters
/// * `pubkey` - The public key of the account whose contact list to update
/// * `contact_pubkeys` - Vector of public keys representing the new complete contact list
///
/// # Returns
/// * `Ok(())` - If the contact list was successfully updated
/// * `Err(WhitenoiseError)` - If there was an error updating the contacts
///
/// # Warning
/// This operation completely replaces the existing contact list. Use with caution.
///
/// # Example
/// ```rust
/// let new_contacts = vec![contact1, contact2, contact3];
/// update_contacts(&my_pubkey, new_contacts).await?;
/// println!("Contact list updated");
/// ```
#[frb]
pub async fn update_contacts(
    pubkey: &PublicKey,
    contact_pubkeys: Vec<PublicKey>,
) -> Result<(), WhitenoiseError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account = whitenoise.fetch_account(pubkey).await?;
    whitenoise.update_contacts(&account, contact_pubkeys).await
}
