// Re-export the types from whitenoise crate for use in the bridge
pub use whitenoise::{Account, AccountSettings, OnboardingState, Whitenoise, WhitenoiseConfig, WhitenoiseError};

pub mod api;

// Include the generated bridge code
mod frb_generated;
pub use frb_generated::*;
