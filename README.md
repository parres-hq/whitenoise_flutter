# White Noise

A secure, private, and decentralized chat app built on Nostr, using the MLS protocol under the hood.

## 🌟 Features

- **Secure Messaging**: End-to-end encryption using Messaging Layer Security (MLS) protocol
- **Decentralized**: Built on the Nostr protocol for censorship resistance
- **Cross-Platform**: Runs on Android, iOS, Linux, macOS, and Windows
- **Group Chats**: Secure group messaging with MLS
- **Media Support**: Send encrypted images, audio messages, and more
- **Modern UI**: Beautiful, responsive interface built with Flutter

## 📱 Supported Platforms

- ✅ **Android** - Fully supported
- ✅ **iOS** - Fully supported
- ⏳ **macOS** - Coming soon
- ⏳ **Windows** - Coming soon
- ⏳ **Linux** - Coming soon
- ⏳ **Web** - Coming soon

## 🏗️ Architecture

- **Frontend**: Flutter (Dart) for cross-platform UI
- **Backend**: Rust crate with flutter_rust_bridge integration
- **Protocols**:
  - [Nostr](https://github.com/nostr-protocol/nips) for decentralized communication
  - [MLS (Messaging Layer Security)](https://www.rfc-editor.org/rfc/rfc9420.txt) for end-to-end encryption
- **Libraries**:
  - [OpenMLS](https://github.com/openmls/openmls) for MLS implementation
  - [rust-nostr](https://github.com/rust-nostr/nostr) for Nostr functionality

## 🚀 Quick Start

### Prerequisites

Make sure you have the following installed:

- **Flutter SDK** (3.24.x or later) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Rust** (latest stable) - [Install Rust](https://rustup.rs/)
- **Just** (command runner) - `cargo install just`
- **flutter_rust_bridge_codegen** - `cargo install flutter_rust_bridge_codegen`
- **Local nostr relays and blossom server** (Optional): for local testing with nostr relays and blossom server:
   ```bash
   git clone https://github.com/parres-hq/whitenoise
   cd whitenoise
   docker-compose up -d
   ```

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/parres-hq/whitenoise_flutter.git
   cd whitenoise_flutter
   ```

2. **Setup the project**
   ```bash
   just setup
   ```
   This command will:
   - Check your development environment
   - Clean any existing builds
   - Install dependencies
   - Generate bridge code
   - Build the Rust library

3. **Run the app**
   ```bash
   just run
   ```

## 🛠️ Development Workflow

### Essential Commands

```bash
# Setup project for new developers
just setup

# Run the app in debug mode
just run

# Run pre-commit checks (formatting, linting, analysis, tests)
just precommit

# Clean everything and regenerate
just reset
```

### Platform-Specific Running

```bash
# Run on specific platforms
just run-ios          # iOS Simulator
just run-android       # Android Emulator
just run-macos         # macOS Desktop
just run-linux         # Linux Desktop
just run-windows       # Windows Desktop

# List available devices
just devices
```

### Code Generation & Dependencies

```bash
# Regenerate flutter_rust_bridge code
just regenerate

# Install dependencies
just deps              # Install both Flutter and Rust deps
just deps-flutter      # Flutter dependencies only
just deps-rust         # Rust dependencies only
```

### Building

```bash
# Build for development
just build-rust-debug  # Rust library (debug)
just build-flutter     # Flutter app for multiple platforms

# Build for production
just build-release     # Complete production build
just build-rust-release # Rust library (release)
```

### Code Quality

```bash
# Format code
just format            # Format both Rust and Dart
just format-rust       # Format Rust only
just format-dart       # Format Dart only

# Lint and analyze
just lint              # Lint both Rust and Dart
just lint-rust         # Rust clippy
just analyze           # Flutter analyzer

# Fix common issues automatically
just fix
```

### Testing

```bash
# Run tests
just test-rust         # Rust unit tests
just test-flutter      # Flutter unit tests (when test/ exists)
just test-integration  # Integration tests
```

### Coverage

You need to install lcov to generate report
```bash
# Mac OS
brew install lcov

# Linux
apt-get install lcov
```

```bash
# Run tests with coverage and check diff coverage for changed files
just check-flutter-coverage

# Or run tests with coverage output manually
flutter test --coverage
# Generate coverage html report
genhtml coverage/lcov.info -o coverage/html 
# Open coverage/html/index.html in your browser
```

### Cleaning

```bash
# Clean builds
just clean-flutter     # Flutter build cache
just clean-rust        # Rust build cache
just clean-bridge      # Generated bridge files
just clean-all         # Everything

# Reset to clean state
just reset
```

### Utilities

```bash
# Project information
just info              # Show versions and dependency info
just doctor            # Check development environment

# Documentation
just docs-rust         # Generate and open Rust docs
```

## 🔄 CI/CD

The project uses GitHub Actions for continuous integration:

- **Triggers**: Pushes and PRs to `main` and `develop` branches
- **Checks**:
  - Rust formatting (`cargo fmt --check`)
  - Dart formatting (`dart format --set-exit-if-changed`)
  - Rust linting (`cargo clippy`)
  - Flutter analysis (`flutter analyze`)
  - Rust tests (`cargo test`)

### Running CI Checks Locally

Before pushing code, run the same checks that CI will run:

```bash
just precommit
```

This ensures your code will pass CI checks.

## 📋 Development Guidelines

### Code Style

- **Rust**: Follow standard Rust conventions, use `cargo fmt` and `cargo clippy`
- **Dart**: Follow Flutter/Dart conventions, use `dart format` and `flutter analyze`
- **Zero warnings policy**: All code must pass linting without warnings

### Commit Workflow

1. Make your changes
2. Run `just precommit` to ensure code quality
3. Commit and push
4. CI will automatically run the same checks

### Adding Dependencies

- **Rust deps**: Add to `rust/Cargo.toml`, then run `just deps-rust`
- **Flutter deps**: Add to `pubspec.yaml`, then run `just deps-flutter`
- **Bridge regeneration**: Run `just regenerate` after adding Rust public functions

## 🏛️ Project Structure

```
whitenoise_flutter/
├── lib/                    # Flutter/Dart source code
│   ├── domain/            # Business logic and models
│   ├── ui/                # User interface screens and widgets
│   ├── config/            # App configuration and providers
│   └── src/rust/          # Generated Rust bridge code
├── rust/                   # Rust source code
│   └── src/               # Rust library implementation
├── integration_test/       # Flutter integration tests
├── .github/workflows/      # CI/CD configuration
├── justfile               # Development commands
└── flutter_rust_bridge.yaml # Bridge configuration
```

## 🔧 Troubleshooting

### Common Issues

1. **Bridge generation fails**
   ```bash
   just clean-bridge
   just regenerate
   ```

2. **Build errors after dependency changes**
   ```bash
   just clean-all
   just deps
   just regenerate
   ```

3. **Platform-specific build issues**
   ```bash
   just doctor  # Check your development environment
   ```

### Getting Help

- Check the [Flutter documentation](https://docs.flutter.dev/)
- Check the [Rust documentation](https://doc.rust-lang.org/)
- Review [flutter_rust_bridge documentation](https://cjycode.com/flutter_rust_bridge/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and run `just precommit`
4. Commit your changes: `git commit -m 'Add amazing feature'`
5. Push to the branch: `git push origin feature/amazing-feature`
6. Open a Pull Request

**Contribution guidelines**

We want to keep our codebase clean, consistent, and easy to contribute to. Here are some guidelines to follow:

- ✅ Unit tests: Add unit tests for all new providers.
- ♻️ Widget design: Try to keep widgets small and simple. Extract complex logic to notifiers. 
- 🏷️ Naming: Shared custom widgets should use the `Wn` prefix for consistency.


## 📜 License

This project is licensed under the [GNU AGPL 3.0](LICENSE) license.

## 📚 Documentation

For more detailed documentation about the project, please visit the [docs/](docs/) folder.

## 🔗 Links

- [Nostr Protocol](https://github.com/nostr-protocol/nips)
- [MLS Protocol RFC](https://www.rfc-editor.org/rfc/rfc9420.txt)
- [OpenMLS Library](https://github.com/openmls/openmls)
- [rust-nostr Library](https://github.com/rust-nostr/nostr)
- [Flutter](https://flutter.dev/)
- [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge)
