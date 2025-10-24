use crate::api::{error::ApiError, group_id_from_string, group_id_to_string};
use chrono::{DateTime, Utc};
use flutter_rust_bridge::frb;
use nostr_sdk::prelude::*;
use whitenoise::{
    FileMetadata as WhitenoiseFileMetadata, MediaFile as WhitenoiseMediaFile, Whitenoise,
};

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct FileMetadata {
    pub original_filename: Option<String>,
    pub dimensions: Option<String>,
    pub blurhash: Option<String>,
}

impl From<WhitenoiseFileMetadata> for FileMetadata {
    fn from(metadata: WhitenoiseFileMetadata) -> Self {
        Self {
            original_filename: metadata.original_filename,
            dimensions: metadata.dimensions,
            blurhash: metadata.blurhash,
        }
    }
}
#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct MediaFile {
    pub id: String,
    pub mls_group_id: String,
    pub account_pubkey: String,
    pub file_path: String,
    pub file_hash: String,
    pub mime_type: String,
    pub media_type: String,
    pub blossom_url: String,
    pub nostr_key: String,
    pub file_metadata: Option<FileMetadata>,
    pub created_at: DateTime<Utc>,
}

impl From<WhitenoiseMediaFile> for MediaFile {
    fn from(media_file: WhitenoiseMediaFile) -> Self {
        Self {
            id: media_file.id.unwrap_or_default().to_string(),
            account_pubkey: media_file.account_pubkey.to_string(),
            mls_group_id: group_id_to_string(&media_file.mls_group_id),
            file_path: media_file.file_path.to_string_lossy().to_string(),
            file_hash: hex::encode(&media_file.file_hash),
            mime_type: media_file.mime_type.to_string(),
            media_type: media_file.media_type.to_string(),
            blossom_url: media_file.blossom_url.unwrap_or_default(),
            nostr_key: media_file.nostr_key.unwrap_or_default(),
            file_metadata: media_file.file_metadata.map(|metadata| metadata.into()),
            created_at: media_file.created_at,
        }
    }
}

#[frb]
pub async fn upload_chat_media(
    account_pubkey: String,
    group_id: String,
    file_path: String,
) -> Result<MediaFile, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let pubkey = PublicKey::parse(&account_pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&pubkey).await?;
    let group_id = group_id_from_string(&group_id)?;

    let media_file = whitenoise
        .upload_chat_media(&account, &group_id, &file_path, None, None)
        .await?;

    Ok(media_file.into())
}
