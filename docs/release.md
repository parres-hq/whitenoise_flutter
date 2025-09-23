# Steps to release a new version

## Building
1. Update version number and increment versionCode in the pubspec.yaml
    1. Always update the build number by 1 (the part after the +)
1. Update the version number in Cargo.toml
    1. This is the flutter rust bridge crate. We keep this in sync with the flutter app's version.
    1. Needs to match the version in the pubspec (without the build number)
1. Update the changelog
    1. Change `Unreleased` to version number with date
    1. Create new `Unreleased` section with subsections just above latest version
1. Run `just precommit` and then commit the changes
1. Run `just release`. This will do a full check and, rebuild everything from scratch and then produce binaries for each platform.
1. The binaries will be output to the `build/releases` folder. There will be a folder there named like the version–e.g. `v0.1.4+5`–containing all the binaries and sha256 hash files.

## Publishing

### iOS Test Flight
1. Upload the `.ipa` file using Transporter to App Store Connect
1. Ensure that you've written good notes for testers
1. Click on the `+` icon under groups on the builds table. Add a group, this will trigger review.

### Android

#### Github
1. Create a git tag named the same as the version plus build number, e.g. `v0.1.4+4`
1. Use this tag to create a new release, named the same as the tag.
1. Write good release notes
1. Publish the release

#### Zapstore
1. You must have the White Noise nsec in order to publish to Zapstore. This should be stored in a .env file with the var `SIGN_WITH=private_key_in_hex`.
1. Run `zapstore publish` and follow the instructions

#### Google Play Store
1. Get KYC'ed
1. Coming soon...
