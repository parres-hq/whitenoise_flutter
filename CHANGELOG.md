# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

### Added
- Add copy npub button in user profile sheet

### Changed

### Deprecated

### Removed

### Fixed
- Fixed blurry splash screen icon on both iOS and Android.

### Security

## [0.1.2] - 2025-07-15

### Added
- Show the npub of each user on the contacts list
- Add developer settings screen with some basic cache management functions
- Add relay management settings screen to view and manage your relays
- Confirmation dialog when signing out
- Fixed back navigation when connecting another account
- QR code scanner for connecting with other users


### Changed

### Deprecated

### Removed
- Remove (for now) the mute and search chat controls from group info screens.
- Remove incorrect group npub from the group info screen.

### Fixed
- Fixed profile picture upload issue.
- Ensure that group creator cannot be included as member
- Prevent duplicate chats on clicking contact
- Bug fixes related to starting new groups on iOS
- Ensure contacts show correct metadata on iOS

### Security

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
