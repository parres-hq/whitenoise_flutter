# Rust API

## What is this about?

 This doc is a place to collect ideas and feedback on what the shape of the rust API should look like for the Flutter app. Currently the rust crate that is built into Tauri is doing a lot of things that I don't think we need to do here in Flutter. For example, there are about 50 commands that are quite Tuari or Svelte specific and I think we can get away from that and do something cleaner here.

## Why do we have a Rust crate in the app at all?

White Noise is implementing [NIP-EE](https://github.com/nostr-protocol/nips/pull/1427/files) to bring highly secure messaging (based on the MLS protocol) to Nostr. The main implementation of the MLS protocol is [OpenMLS](https://github.com/openmls/openmls) which is written in Rust. We also wrote a set of [rust crates](https://github.com/rust-nostr/nostr/tree/master/crates/nostr-mls) that wrap OpenMLS and provide the extra functionality required to make MLS function on Nostr. Because these crates are well tested and Rust is highly performant and type/memory safe, we'd like to continue using these crates to provide the core functionality to our apps. This also means that we're front-end independent. Want to drive White Noise via a CLI? We can do that. Want to use the crate to build a website? We can do that.

## How does the Flutter app talk to the Rust crate?

We're using [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge) to automatically generate bindings from our rust code to this app.

## Application State

Since we'll be using Riverpod to create high-level providers that give access global state, we should be able to simplify the API significantly and depend on a high-level `StreamProvider` (or several) that provide updates from the backend to the front-end continuously.

### State Objects

Very very subject to change and discussion - this is only a first pass.

### Whitenoise

```rust
struct Whitenoise {
    config: WhitenoiseConfig,    // Config object used to instantiate
    accounts: BTreeSet<Account>, // A BTreeSet of Accounts that are currently signed into the app
    active_account: PublicKey,   // The PublicKey of the currently active account in the UI
}
```

### Accounts

```rust
struct Account {
    pubkey: PublicKey,               // Nostr public key - in hex format
    metadata: Metadata,              // Kind-0 metadata of a user
    settings: AccountSettings,       // White Noise specific app preferences
    onboarding: AccountOnboarding,   // White Noise specific onboarding steps
    contacts: BTreeSet<PublicKey>,   // Set of pubkeys of the user's contacts (from their kind 3 event)
    last_used: Timestamp,            // The last time the account was used
    last_synced: Timestamp,          // The last time the account was synced up fully to relays
    active: bool,                    // Is this account currently active - (do we need this?)
    groups: BTreeSet<GroupMetadata>, // A BTreeSet of GroupMetadata for the groups the user is part of (includes both active and inactive groups)
    welcomes: BTreeSet<Welcome>,     // A BTreeSet of welcomes for the user (includes pending, accepted, and dismissed welcomes)
}
```

```rust
struct Metadata {
    name: Option<String>,            // Name
    display_name: Option<String>,    // Display name (always show this first, fallback to name)
    about: Option<String>,           // Bio
    website: Option<String>,         // URL
    picture: Option<String>,         // Avatar image URL
    banner: Option<String>,          // Banner image URL
    nip05: Option<String>,           // NIP-05 verification
    lud06: Option<String>,           // LUD-06 lightning URL - rarely used
    lud16: Option<String>,           // LUD-16 lightning URL
    // Other custom fields can also show up here, always of the Option<String> type
}

```rust
struct AccountSettings {
    dark_theme: bool,       // Dark mode
    dev_mode: bool,         // Dev mode
    lockdown_mode: bool,    // Lockdown mode (doesn't currently do anything)
}
```

```rust
struct AccountOnboarding {
    inbox_relays: bool,         // Do they have an inbox relays list event (kind: 10050)
    key_package_relays: bool,   // Do they have a key package relays list event (kind: 10051)
    publish_key_package: bool,  // Have they published a key package
}
```

### Groups

```rust
/// High level details about groups. Doesn't include the messages of the group.
struct GroupMetadata {
    mls_group_id: GroupId,                   // The MLS Group ID - never changes
    nostr_group_id: [u8; 32],                // The group ID used for identifying this group on relays - can change
    name: String,                            // The name of the group
    description: String,                     // The description of the group
    admin_pubkeys: BTreeSet<PublicKey>,      // The list of admin pubkeys
    last_message_id: Option<EventId>,        // The ID of the latest message
    last_message_at: Option<Timestamp>,      // The timestamp of the latest message
    last_message_preview: Option<String>,    // The preview text of the latest message to show in the chats list
    group_type: GroupType,                   // The type of group (DM or Group)
    state: GroupState,                       // Whether the group is active or not
}
```

```rust
/// Details of the group. Including all messages. Only loaded when you actually open a group.
/// Ideally, we will want to progressively load the messages.
struct Group {
    metadata: GroupMetadata,     // The group metadata
    messages: BTreeSet<Message>, // A BTreeSet of all the messages. See `Message` below
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

### Messages

```rust
struct Message {
    state: MessageState,            // The state of the message
    id: EventId,                    // The ID of the message event
    pubkey: PublicKey,              // PublicKey of the sender
    kind: Kind,                     // Nostr event kind
    created_at: Timestamp,          // When was the message sente
    content: String,                // Content
    tags: Tags,                     // Nostr event tags
    reactions: BTreeSet<Message>,   // Optional set of messages that are reacting to this message
    reaction_to: Option<Message>,   // Optional message that this message is reacting to. Will only be set when it's a kind 7 message
    reaction_summary: HashMap,      // Summary of reactions to this message e.g. {❤️: 3, 👍: 1}
    replies: BTreeSet<Message>,     // Set of messages that are replying to this message
    reply_to: Option<Message>,      // Optional message that this message is replying to
}
```

```rust
enum MessageState {
    Created,    // The message was created successfully and stored but we don't yet know if it was published to relays.
    Processed,  // The message was successfully processed and stored in the database
    Deleted,    // The message was deleted by the original sender - via a delete event
}
```

### Welcomes

```rust
struct Welcome {
    mls_group_id: GroupId,                      // the mls_group_id
    nostr_group_id: [u8; 32],                   // the nostr_group_id
    group_name: String,                         // group name
    group_description: String,                  // group description
    group_admin_pubkeys: BTreeSet<PublicKey>,   // the admin pubkeys
    group_relays: BTreeSet<RelayUrl>,           // the relays of the group
    welcomer: PublicKey,                        // the pubkey of the person who sent the welcome message
    member_count: u32,                          // the number of members in the group
    state: WelcomeState,                        // The state of the welcome
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

## Needed Functionality

These aren't meant to be method signatures or the API itself, this is simply pseudo-methods (in the style of a REST API) that give us an idea of what we need. Much of this will likely be replaced by streamed state and providers.

### Whitenoise

- delete_all_data(): clears all app data. updates the `Whitenoise` state object.

### Accounts
- create_account(): generates a new nostr keypair and creates an account. updates the `Whitenoise` state object.
- login(secret_key): creates an account using a nostr private key. updates the `Whitenoise` state object.
- logout(pub_key): removes an account (we need to decide if this also deletes all the groups/messages/etc. for that user or not). updates the `Whitenoise` state object.

### Groups

### Messages

### KeyPackages

### Welcomes
