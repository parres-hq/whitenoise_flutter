# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Loading skeleton components for chat and contact lists to improve user experience during data loading
- Global No relay indicator
- [Android] Sensitive clipboard copy for private key (nsec).
- Group info update functionality (name and description).
- Add back buttons in auth flow screens for easier navigation.
- Paste from clipboard functionality (cta) in new chat bottom sheet.

### Changed

- Improved chat title tap area for easier navigation to contact info

### Deprecated

### Removed
- Removed relay pull-to-refresh

### Fixed
- Fixed get user logic, to show metadata when searching a new npub
- Fixes profile edition with outdated metadata
- Fixes pubkeys formatting and pubkeys comparisons in different format
- Fixes follow/unfollow in start chat sheet
- Fixes wrong relay status error when switching accounts
- Fixes scroll to bototm inside of chats
- Fixed profile image not showing up chatlist after login
- Fixes auto-scroll to bottom when keyboard opens

### Security

## [0.1.3] - 2025-08-09

### Added

- Add copy npub button in user profile sheet
- Fixes double sheet loading in contact bottom sheet

### Fixed

- Improved relay selection and connection logic
- Improved metadata fetching
- Fixed failing DM group creation in nearly all cases. Note: We're still seeing issues with creating multi-person groups (fix coming soon)
- Fixed blurry splash screen icon on both iOS and Android.
- Fixed absence of border on some contact avatars
- Fixed irregular textfield and button sizes
- Fixed active profile sorting (active profile comes first in account switcher).

## [0.1.2] - 2025-07-15

### Added

- Show the npub of each user on the contacts list
- Add developer settings screen with some basic cache management functions
- Add relay management settings screen to view and manage your relays
- Confirmation dialog when signing out
- Fixed back navigation when connecting another account
- QR code scanner for connecting with other users

### Removed

- Remove (for now) the mute and search chat controls from group info screens.
- Remove incorrect group npub from the group info screen.

### Fixed

- Fixed profile picture upload issue.
- Ensure that group creator cannot be included as member
- Prevent duplicate chats on clicking contact
- Bug fixes related to starting new groups on iOS
- Ensure contacts show correct metadata on iOS

## [0.1.1] - 2025-07-10

### Fixed

- Improved speed of onboarding flow for newly created accounts
- Improved speed of contact list and metadata fetching for accounts
- Improved speed and smoothness of contact list scrolling
- Improved UI details of chat bubbles
- Fixed errors related to inviting users

### Changed

- Removed NIP-04 invites and replaced with OS level share sheets

## [0.1.0] - 2025-07-09

Initial release of White Noise!
