// This is where the account related functions will be

use crate::Whitenoise;
use whitenoise::{Account, WhitenoiseError};

pub async fn create_identity(whitenoise: &mut Whitenoise) -> Result<Account, WhitenoiseError> {
    whitenoise.create_identity().await
}

pub async fn login(whitenoise: &mut Whitenoise, nsec_or_hex_privkey: String) -> Result<Account, WhitenoiseError> {
    whitenoise.login(nsec_or_hex_privkey).await
}

pub async fn logout(whitenoise: &mut Whitenoise, account: &Account) -> Result<(), WhitenoiseError> {
    whitenoise.logout(account).await
}

pub fn update_active_account(whitenoise: &mut Whitenoise, account: &Account) -> Result<Account, WhitenoiseError> {
    whitenoise.update_active_account(account)
}
