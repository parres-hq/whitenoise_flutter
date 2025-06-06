# Scripts

This directory contains helper scripts for the White Noise Flutter project. We recommend using the `justfile` commands for most operations as they provide a more comprehensive and organized workflow.

## Quick Start

```bash
# List all available commands
just

# Set up the project for the first time
just setup

# Quick development workflow
just dev

# Full build from scratch
just build
```

## Main Workflows

### Development Workflow (`just dev`)
The fastest way to get up and running during development:
- Cleans and regenerates bridge code
- Checks Rust code validity
- Ensures Flutter dependencies are installed
- Runs the Flutter app with hot reload

### Build Workflow (`just build`)
Complete build process from scratch:
- Cleans all build artifacts
- Installs/updates all dependencies
- Regenerates bridge code
- Builds Rust library (debug)
- Runs code analysis

### Production Build (`just build-release`)
Optimized build for production:
- Cleans everything
- Regenerates bridge code
- Installs dependencies
- Builds Rust library in release mode

## Core Operations

### Code Generation
```bash
# Generate flutter_rust_bridge code
just generate

# Clean and regenerate bridge code
just regenerate
```

### Dependencies
```bash
# Install/update all dependencies (Rust + Flutter)
just deps

# Install only Rust dependencies
just deps-rust

# Install only Flutter dependencies
just deps-flutter

# Upgrade Flutter dependencies
just upgrade-flutter
```

### Rust Operations
```bash
# Quick check (fast compilation check)
just check-rust

# Build debug version
just build-rust-debug

# Build release version
just build-rust-release

# Run tests
just test-rust

# Format code
just format-rust

# Lint with clippy
just lint-rust

# Generate and open documentation
just docs-rust
```

### Flutter Operations
```bash
# Run app in debug mode
just run

# Run app without hot reload
just run-cold

# Run app on web
just run-web

# Build for all platforms
just build-flutter

# Run analyzer
just analyze

# Format Dart code
just format-dart

# Run Flutter tests
just test-flutter
```

### Cleaning
```bash
# Clean only bridge files (fastest)
just clean-bridge

# Clean Flutter build cache
just clean-flutter

# Clean Rust build cache
just clean-rust

# Clean everything
just clean-all
```

### Code Quality
```bash
# Format all code (Rust + Dart)
just format

# Lint all code (Rust + Dart)
just lint

# Auto-fix common issues
just fix
```

### Utilities
```bash
# Show project info and status
just info

# Check development environment
just doctor

# Reset project to clean state
just reset

# Complete setup for new developers
just setup
```

## Shell Scripts

### `build.sh`
Comprehensive build script that performs a complete build from scratch:
- Validates development environment
- Cleans all build artifacts
- Installs dependencies
- Regenerates bridge code
- Builds Rust library
- Runs code analysis
- Optionally runs tests with `--with-tests` flag

Usage:
```bash
./scripts/build.sh              # Standard build
./scripts/build.sh --with-tests # Build with tests
```

### `dev.sh`
Quick development script optimized for fast iteration:
- Minimal cleaning (bridge files only)
- Regenerates bridge code
- Checks Rust code validity
- Ensures Flutter dependencies
- Optionally runs analysis with `--analyze` flag
- Optionally skips running app with `--no-run` flag

Usage:
```bash
./scripts/dev.sh              # Standard dev workflow
./scripts/dev.sh --analyze    # Include analysis
./scripts/dev.sh --no-run     # Setup only, don't run app
```

## Flutter Rust Bridge Workflow

White Noise uses `flutter_rust_bridge` to connect Flutter (Dart) with Rust. Here's the typical workflow:

1. **Make changes to Rust API** in `rust/src/api/`
2. **Regenerate bridge code**: `just regenerate`
3. **Test the changes**: `just run`

### How flutter_rust_bridge Works

- **Code Generation**: `flutter_rust_bridge generate` analyzes your Rust API and generates Dart bindings
- **Compilation**: Rust code is compiled into a native library that Flutter can call
- **No Separate Compilation**: You don't need to compile Rust separately - the bridge generation handles everything

### Generated Files

The bridge generation creates these files:
- `rust/src/frb_generated.rs` - Rust bridge code
- `lib/src/rust/api.dart` - Dart API bindings
- `lib/src/rust/frb_generated.dart` - Dart bridge code
- `lib/src/rust/frb_generated.io.dart` - Platform-specific bindings
- `lib/src/rust/frb_generated.web.dart` - Web platform bindings

## Common Issues and Solutions

### Build Errors
```bash
# Try a complete reset
just reset

# Or clean everything and rebuild
just clean-all
just build
```

### Bridge Generation Issues
```bash
# Check if flutter_rust_bridge is installed
just doctor

# Install if missing
cargo install flutter_rust_bridge_codegen

# Clean and regenerate
just clean-bridge
just generate
```

### Dependency Issues
```bash
# Update all dependencies
just deps
just upgrade-flutter

# Check for dependency conflicts
flutter pub deps
cd rust && cargo tree
```

### Performance During Development
- Use `just dev` instead of `just build` for faster iteration
- Use `just check-rust` instead of `just build-rust-debug` for quick validation
- Use `just clean-bridge` instead of `just clean-all` when only bridge files need refreshing

## Environment Setup

### Required Tools
- Flutter SDK
- Rust toolchain (rustc, cargo)
- flutter_rust_bridge_codegen

### Verification
```bash
# Check if everything is properly installed
just doctor

# Show detailed project information
just info
```

### First-Time Setup
```bash
# Complete setup for new developers
just setup
```

This will check your environment, clean everything, install dependencies, generate bridge code, and build the project.
