# What is this about?

This doc is a place to collect ideas and feedback on what the shape of the rust API should look like for the Flutter app. Currently the rust crate that is built into Tauri is doing a lot of things that I don't think we need to do here in Flutter. For example, there are about 50 commands that are quite Tuari or Svelte specific and I think we can get away from that and do something cleaner here.

# Why do we have a Rust crate in the app at all?

White Noise is implementing [NIP-EE](https://github.com/nostr-protocol/nips/pull/1427/files) to bring highly secure messaging (based on the MLS protocol) to Nostr. The main implementation of the MLS protocol is [OpenMLS](https://github.com/openmls/openmls) which is written in Rust. We also wrote a set of [rust crates](https://github.com/rust-nostr/nostr/tree/master/crates/nostr-mls) that wrap OpenMLS and provide the extra functionality required to make MLS function on Nostr. Because these crates are well tested and Rust is highly performant and type/memory safe, we'd like to continue using these crates to provide the core functionality to our apps. This also means that we're front-end independent. Want to drive White Noise via a CLI? We can do that. Want to use the crate to build a website? We can do that.

# How does the Flutter app talk to the Rust crate?

We're using [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge) to automatically generate bindings from our rust code to this app.

# Application State

Since we'll be using Riverpod to create high-level providers that give access global state, we should be able to simplify the API significantly and depend on a high-level `StreamProvider` (or several) that provide updates from the backend to the front-end continuously.

# Structs

## Whitenoise

```rust
struct WhitenoiseState {
    config: WhitenoiseConfig,           // The config object passed in to initialize Whitenoise
    accounts: Vec<Account>,             // Vec of accounts that are signed in
    active_account: Option<PublicKey>,  // Optional in case there is no signed in accounts
}
```

## Accounts

```rust
struct Account {
    pubkey:         PublicKey,          // Nostr public key - in hex format
    metadata:       Metadata,           // Kind-0 metadata of a user
    settings:       AccountSettings,    // White Noise specific app preferences
    onboarding:     AccountOnboarding,  // White Noise specific onboarding steps
    contacts:       Vec<PublicKey>,     // Set of pubkeys of the user's contacts (from their kind 3 event)
    last_used:      Timestamp,          // The last time the account was used
    last_synced:    Timestamp,          // The last time the account was synced up fully to relays
    active:         bool,               // Is this account currently active - (do we need this?)
    groups:         Vec<GroupMetadata>, // GroupMetadata for the groups the user is part of (includes both active and inactive groups)
    welcomes:       Vec<Welcome>,       // Welcomes for the user (includes pending, accepted, and dismissed welcomes)
}
```

```rust
struct Metadata {
    name:         Option<String>,    // Name
    display_name: Option<String>,    // Display name (always show this first, fallback to name)
    about:        Option<String>,    // Bio
    website:      Option<String>,    // URL
    picture:      Option<String>,    // Avatar image URL
    banner:       Option<String>,    // Banner image URL
    nip05:        Option<String>,    // NIP-05 verification
    lud06:        Option<String>,    // LUD-06 lightning URL - rarely used
    lud16:        Option<String>,    // LUD-16 lightning URL
    // Other custom fields can also show up here, always of the Option<String> type
}
```

```rust
struct AccountSettings {
    dark_theme:    bool,    // Dark mode
    dev_mode:      bool,    // Dev mode
    lockdown_mode: bool,    // Lockdown mode (doesn't currently do anything)
}
```

```rust
struct AccountOnboarding {
    inbox_relays:        bool,    // Do they have an inbox relays list event (kind: 10050)
    key_package_relays:  bool,    // Do they have a key package relays list event (kind: 10051)
    publish_key_package: bool,    // Have they published a key package
}
```

## Groups

```rust
/// High level details about a group. Messages are loaded separately via pagination.
struct Group {
    mls_group_id:        GroupId,           // The MLS Group ID - never changes
    nostr_group_id:      [u8; 32],          // The group ID used for identifying this group on relays - can change
    name:                String,            // The name of the group
    description:         String,            // The description of the group
    admin_pubkeys:       Vec<PublicKey>,    // The list of admin pubkeys
    last_message_id:     Option<EventId>,   // The ID of the latest message
    last_message_at:     Option<Timestamp>, // The timestamp of the latest message
    last_message_preview: Option<String>,   // The preview text of the latest message to show in the chats list
    group_type:          GroupType,         // The type of group (DM or Group)
    state:               GroupState,        // Whether the group is active or not
}
```

```rust
enum GroupType {
    DirectMessage,  // Just two members
    Group           // More than two members
}
```

```rust
enum GroupState {
    Active,     // The group is active
    Inactive,   // The group is inactive, e.g. users have left or when welcome has been declined
    Pending,    // The group is pending, e.g. users are invited to but haven't joined yet
}
```

## Messages

```rust
struct Message {
    state:            MessageState,    // The state of the message
    id:               EventId,         // The ID of the message event
    pubkey:           PublicKey,       // PublicKey of the sender
    kind:             Kind,            // Nostr event kind
    created_at:       Timestamp,       // When was the message sente
    content:          String,          // Content
    tags:             Tags,            // Nostr event tags
    reactions:        Vec<Message>,    // Optional set of messages that are reacting to this message
    reaction_to:      Option<Message>, // Optional message that this message is reacting to. Will only be set when it's a kind 7 message
    reaction_summary: HashMap,         // Summary of reactions to this message e.g. {❤️: 3, 👍: 1}
    replies:          Vec<Message>,    // Set of messages that are replying to this message
    reply_to:         Option<Message>, // Optional message that this message is replying to
}
```

```rust
enum MessageState {
    Created,    // The message was created successfully and stored but we don't yet know if it was published to relays.
    Processed,  // The message was successfully processed and stored in the database
    Deleted,    // The message was deleted by the original sender - via a delete event
}
```

```rust
// Pagination cursor
struct MessageCursor {
    timestamp:   Timestamp,     // When the message was created
    message_id:  EventId,       // The message's event ID
    direction:   PageDirection, // Which direction to load messages
}
```

```rust
enum PageDirection {
    Forward,  // Load newer messages
    Backward, // Load older messages
}
```

```rust
struct MessagePage {
    messages:    Vec<Message>,          // The messages in this page
    next_cursor: Option<MessageCursor>, // Cursor for loading the next page
    prev_cursor: Option<MessageCursor>, // Cursor for loading the previous page
    has_more:    bool,                  // Whether there are more messages to load
}
```

## Welcomes

```rust
struct Welcome {
    mls_group_id:        GroupId,          // the mls_group_id
    nostr_group_id:      [u8; 32],         // the nostr_group_id
    group_name:          String,           // group name
    group_description:   String,           // group description
    group_admin_pubkeys: Vec<PublicKey>,   // the admin pubkeys
    group_relays:        Vec<RelayUrl>,    // the relays of the group
    welcomer:            PublicKey,        // the pubkey of the person who sent the welcome message
    member_count:        u32,              // the number of members in the group
    state:               WelcomeState,     // The state of the welcome
}
```

```rust
enum WelcomeState {
    Pending,    // The welcome is pending
    Accepted,   // The welcome was accepted
    Declined,   // The welcome was declined
    Ignored,    // The welcome was ignored
}
```

# Methods

```rust
/// =========================================
/// Initialization and Basics
/// =========================================

// Initialize app state from the database
async fn initialize_whitenoise(config: WhitenoiseConfig) -> Result<WhitenoiseState, Error> {
    // Load from database and return initial state
}

// Delete all data from the app databases
async fn delete_all_data() -> Result<(), Error> {
    // Delete everything from the databases
}

/// =========================================
/// Accounts
/// =========================================

/// Creates a new account by generating a new Nostr keypair.
/// Returns the new account's public key and updates the WhitenoiseState.
async fn create_account() -> Result<PublicKey, Error> {
    // Implementation
}

/// Logs in an existing account using a Nostr private key.
/// Returns the account's public key and updates the WhitenoiseState.
async fn login(secret_key: String) -> Result<PublicKey, Error> {
    // Implementation
}

/// Logs out an account by its public key.
/// Optionally deletes all associated data (groups, messages, etc.).
/// Updates the WhitenoiseState.
async fn logout(pubkey: PublicKey, delete_data: bool) -> Result<(), Error> {
    // Implementation
}

/// Update the active account
/// Updates the WhitenoiseState
async fn update_active_account(pubkey: PublicKey) -> Result<(), Error> {
    // Implementation
}

/// Updates an account's metadata (kind 0 event).
/// Returns the updated account and updates the WhitenoiseState.
async fn update_account_metadata(pubkey: PublicKey, metadata: Metadata) -> Result<Account, Error> {
    // Implementation
}

/// Updates an account's settings.
/// Returns the updated account and updates the WhitenoiseState.
async fn update_account_settings(pubkey: PublicKey, settings: AccountSettings) -> Result<Account, Error> {
    // Implementation
}

/// Updates an account's contacts list (kind 3 event).
/// Returns the updated account and updates the WhitenoiseState.
async fn update_account_contacts(pubkey: PublicKey, contacts: Vec<PublicKey>) -> Result<Account, Error> {
    // Implementation
}

/// Updates an account's onboarding status.
/// Returns the updated account and updates the WhitenoiseState.
async fn update_account_onboarding(pubkey: PublicKey, onboarding: AccountOnboarding) -> Result<Account, Error> {
    // Implementation
}

/// =========================================
/// Groups
/// =========================================

/// Creates a new group with the specified members and admins.
/// Returns the created group and updates the WhitenoiseState.
async fn create_group(
    name: String,
    description: String,
    member_pubkeys: Vec<PublicKey>,
    admin_pubkeys: Vec<PublicKey>,
) -> Result<Group, Error> {
    // Implementation
}

/// Joins an existing group using a welcome message.
/// Returns the joined group and updates the WhitenoiseState.
async fn join_group(welcome: Welcome) -> Result<Group, Error> {
    // Implementation
}

/// Leaves a group.
/// Updates the WhitenoiseState.
async fn leave_group(group_id: GroupId) -> Result<(), Error> {
    // Implementation
}

/// Updates a group's metadata including name, description, and admin list.
/// Returns the updated group and updates the WhitenoiseState.
async fn update_group_metadata(
    group_id: GroupId,
    name: Option<String>,
    description: Option<String>,
    admin_pubkeys: Option<Vec<PublicKey>>,
) -> Result<Group, Error> {
    // Implementation
}

/// Adds a new member to the group.
/// Returns the updated group and updates the WhitenoiseState.
async fn add_member(
    group_id: GroupId,
    member_pubkey: PublicKey,
) -> Result<Group, Error> {
    // Implementation
}

/// Removes a member from the group.
/// Returns the updated group and updates the WhitenoiseState.
async fn remove_member(
    group_id: GroupId,
    member_pubkey: PublicKey,
) -> Result<Group, Error> {
    // Implementation
}

// Rotate your key in the group
// Will be done periodically for forward secrecy
async fn rotate_key_in_group(
    group_id: GroupId,
) -> Result<(), Error> {
    // Implementation
}

/// =========================================
/// Messages
/// =========================================

// Method to load messages for a group with pagination.
// This will be backed by an LRU cache that will hold the most recently viewed messages in memory and load from the database only when necessary.
async fn load_messages(
    group_id: GroupId,
    cursor: Option<MessageCursor>,
    limit: usize,
) -> Result<MessagePage, Error> {
    // Returns a page of messages with pagination info
}

/// Sends a new message to a group.
/// Returns the created message and updates the WhitenoiseState.
async fn send_message(
    group_id: GroupId,
    message: String,
    kind: u16,
    tags: Option<Vec<Tag>>,
    uploaded_files: Option<Vec<FileUpload>>,
) -> Result<MessageWithTokens, Error> {}

/// =========================================
/// Key Packages
/// =========================================

/// Publishes a new key package for the account to relays
async fn publish_new_key_package(pubkey: PublicKey) -> Result<(), Error> {}

/// Check to see if a valid key package exists for a user
async fn valid_key_package_exists(pubkey: PublicKey) -> Result<bool, Error>

/// Delete all key packages from relays
async fn delete_all_key_packages(pubkey: PublicKey) -> Result<bool, Error>
```

# Tauri Commands → New API

| Old Tauri Command                   | What it did                                               | New Method                          | What it does / Why we don't need it                         |
| ----------------------------------- | --------------------------------------------------------- | ----------------------------------- | ----------------------------------------------------------- |
| n/a                                 | n/a                                                       | `initialize_whitenoise`             | intialize the app and return comprehensive app state object |
| `is_mobile`                         | Checks if running on mobile platform                      | n/a                                 | we can use dart methods directly for this                   |
| `is_platform`                       | Returns the current platform identifier                   | n/a                                 | we can use dart methods directly for this                   |
| `delete_all_data`                   | Deletes all data from the application                     | `delete_all_data`                   | Deletes all data from the application                       |
| `create_identity`                   | Create a new identity and set it active                   | `create_account`                    | Create a new identity and set it active                     |
| `login`                             | Logs in with given public key                             | `login`                             | Log in with given public key and set it active              |
| `logout`                            | Logs out the given public key                             | `logout`                            | Logs out the given public key                               |
| `set_active_account`                | Sets the active account                                   | `update_active_account`             | Sets the active account                                     |
| `get_accounts`                      | Lists all accounts                                        | n/a                                 | `initialize_whitenoise` returns comprehensive state object  |
| `update_account_onboarding`         | Updates onboarding status for account                     | `update_account_onboarding`         | Updates onboarding status for account                       |
| `publish_metadata_event`            | Publishes metadata event for an account                   | `update_account_metadata`           | Update account metadata & publish new kind:0 event          |
| n/a                                 | n/a                                                       | `update_account_settings`           | Update account settings                                     |
| n/a                                 | n/a                                                       | `update_account_contacts`           | Update account contact list & publish new kind:3 event      |
| `fetch_relays_list`                 | Fetched a relays list of a specific kind for a given user |                                     |                                                             |
| `get_nostr_wallet_connect_balance`  | Gets balance from connected NWC wallet                    |                                     |                                                             |
| `has_nostr_wallet_connect_uri`      | Checks if NWC URI is configured                           |                                     |                                                             |
| `remove_nostr_wallet_connect_uri`   | Removes NWC URI for active account                        |                                     |                                                             |
| `set_nostr_wallet_connect_uri`      | Sets NWC URI for active account                           |                                     |                                                             |
| `export_nsec`                       | Exports NSEC key for a public key                         |                                     |                                                             |
| `fetch_relays`                      | Fetches status of connected Nostr relays                  |                                     |                                                             |
| `fetch_enriched_contact`            | Fetches enriched contact information                      |                                     |                                                             |
| `query_enriched_contact`            | Queries enriched contact information                      |                                     |                                                             |
| `search_for_enriched_contacts`      | Searches for enriched contacts                            |                                     |                                                             |
| `invite_to_white_noise`             | Sends invitation to White Noise                           |                                     |                                                             |
| `init_nostr_for_current_user`       | Initializes Nostr for current user                        |                                     |                                                             |
| `publish_relay_list`                | Publishes relay list to Nostr                             |                                     |                                                             |
| `query_enriched_contacts`           | Queries multiple enriched contacts                        |                                     |                                                             |
| `fetch_enriched_contacts`           | Fetches multiple enriched contacts                        |                                     |                                                             |
| `query_contacts_with_metadata`      | Queries contacts with metadata                            |                                     |                                                             |
| `fetch_contacts_with_metadata`      | Fetches contacts with metadata                            |                                     |                                                             |
| `publish_new_key_package`           | Publishes new MLS key package                             | `publish_new_key_package`           | Publishes new MLS key package                               |
| `valid_key_package_exists_for_user` | Checks if valid key package exists                        | `valid_key_package_exists_for_user` | Checks if valid key package exists                          |
| `delete_all_key_packages`           | Deletes all key packages from relays                      | `delete_all_key_packages`           | Deletes all key packages from relays                        |
| `create_group`                      | Creates a new MLS group                                   | `create_group`                      | Creates new MLS group                                       |
| `get_group_and_messages`            | Gets group and its messages                               | `load_messages`                     | Loads a paginated list of messages for a given group        |
| `rotate_key_in_group`               | Rotates key in a group                                    | `rotate_key_in_group`               | Rotates key in a group                                      |
| `send_mls_message`                  | Sends message to MLS group                                | `send_message`                      | Sends a message to a group                                  |
| `accept_welcome`                    | Accepts a group welcome                                   | `join_group`                        | Joins a group by accepting a welcome                        |
| `decline_welcome`                   | Declines a group welcome                                  | `decline_join_group`                | Declines to join a group by welcome                         |
| n/a                                 | n/a                                                       | `leave_group`                       | Leaves a group                                              |
| n/a                                 | n/a                                                       | `add_member`                        | Adds member to a group - only admins can perform            |
| n/a                                 | n/a                                                       | `remove_member`                     | Removes member from a group - only admins can perform       |
| n/a                                 | n/a                                                       | `update_group_metadata`             | Updates group metadata - only admins can perform            |
| `get_group_members`                 | Gets members of a group                                   | n/a                                 | Included in Group struct                                    |
| `get_group_relays`                  | Gets relays for a group                                   | n/a                                 | Included in Group struct                                    |
| `delete_message`                    | Deletes message from MLS group                            | n/a                                 | We will use `send_message` with kind:5 UnsignedEvent        |
| `get_active_groups`                 | Gets all active groups                                    | n/a                                 | Included in Account struct                                  |
| `get_group`                         | Gets single MLS group by ID                               | n/a                                 | Included in Group struct                                    |
| `get_group_admins`                  | Gets admins of a group                                    | n/a                                 | Included in Group struct                                    |
| `upload_file`                       | Uploads file to storage                                   |                                     |                                                             |
| `upload_media`                      | Uploads media content to Blossom service                  |                                     |                                                             |
| `fetch_file`                        | Fetches file from storage                                 |                                     |                                                             |
| `delete_file`                       | Deletes file from storage                                 |                                     |                                                             |
| `query_message`                     | Queries a specific message                                | n/a                                 | Not needed                                                  |
| `pay_invoice`                       | Pays a Lightning invoice                                  |                                     |                                                             |
| `get_welcome`                       | Gets a specific welcome                                   | n/a                                 | Included in Account struct                                  |
| `get_welcomes`                      | Gets all welcomes                                         | n/a                                 | Included in Account struct                                  |
| `decrypt_content`                   | Decrypts content using Nostr encryption                   | n/a                                 | Not needed                                                  |
| `encrypt_content`                   | Encrypts content using Nostr encryption                   | n/a                                 | Not needed                                                  |
