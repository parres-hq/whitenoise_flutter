# Justfile for White Noise Flutter project

# Default recipe - show available commands
default:
    @just --list

# ==============================================================================
# MAIN WORKFLOWS
# ==============================================================================

# Quick development workflow: regenerate bridge + check rust + run flutter
dev: regenerate check-rust deps-flutter run

# Development workflow for iOS simulator
dev-ios: regenerate check-rust deps-flutter run-ios

# Development workflow for Android emulator
dev-android: regenerate check-rust deps-flutter run-android

# Development workflow for macOS desktop
dev-macos: regenerate check-rust deps-flutter run-macos

# Full build workflow: clean everything + regenerate + build + analyze
build: clean-all regenerate deps build-rust-debug deps-flutter analyze

# Production build workflow
build-release: clean-all regenerate deps build-rust-release deps-flutter

# Pre-commit checks: run the same checks as CI locally
precommit: check-rust-format check-dart-format lint-rust analyze test-flutter test-rust
    @echo "✅ All pre-commit checks passed!"

# ==============================================================================
# CODE GENERATION
# ==============================================================================

# Generate Rust bridge code
generate:
    @echo "🔄 Generating flutter_rust_bridge code..."
    flutter_rust_bridge_codegen generate

# Clean and regenerate Rust bridge code
regenerate: clean-bridge generate

# ==============================================================================
# DEPENDENCIES
# ==============================================================================

# Install/update all dependencies
deps: deps-rust deps-flutter

# Install/update Rust dependencies
deps-rust:
    @echo "📦 Installing Rust dependencies..."
    cd rust && cargo fetch

# Install/update Flutter dependencies
deps-flutter:
    @echo "📦 Installing Flutter dependencies..."
    flutter pub get

# Upgrade Flutter dependencies
upgrade-flutter:
    @echo "⬆️ Upgrading Flutter dependencies..."
    flutter pub upgrade

# ==============================================================================
# RUST OPERATIONS
# ==============================================================================

# Check Rust code (fast compilation check)
check-rust:
    @echo "🔍 Checking Rust code..."
    cd rust && cargo check

# Build Rust library for development (debug)
build-rust-debug:
    @echo "🔨 Building Rust library (debug)..."
    cd rust && cargo build

# Build Rust library for release
build-rust-release:
    @echo "🔨 Building Rust library (release)..."
    cd rust && cargo build --release

# Test Rust code
test-rust:
    @echo "🧪 Testing Rust code..."
    cd rust && cargo test

# Format Rust code
format-rust:
    @echo "💅 Formatting Rust code..."
    cd rust && cargo fmt

# Check Rust code formatting (CI-style check)
check-rust-format:
    @echo "🔍 Checking Rust code formatting..."
    cd rust && cargo fmt --check

# Lint Rust code
lint-rust:
    @echo "🧹 Linting Rust code..."
    cd rust && cargo clippy --package rust_lib_whitenoise -- -D warnings

# Run Rust documentation
docs-rust:
    @echo "📚 Generating Rust documentation..."
    cd rust && cargo doc --open

# ==============================================================================
# FLUTTER OPERATIONS
# ==============================================================================

# Run Flutter app in debug mode
run:
    @echo "🚀 Running Flutter app..."
    flutter run

# Run Flutter app with hot reload disabled
run-cold:
    @echo "🚀 Running Flutter app (cold)..."
    flutter run --no-hot

# Run Flutter app on iOS simulator
run-ios:
    @echo "📱 Running Flutter app on iOS simulator..."
    flutter run -d "iPhone 16 Pro"

# Run Flutter app on Android emulator
run-android:
    @echo "🤖 Running Flutter app on Android emulator..."
    flutter run -d "sdk gphone64"

# Run Flutter app on macOS desktop
run-macos:
    @echo "🖥️ Running Flutter app on macOS..."
    flutter run -d macos

# Run Flutter app on Linux desktop
run-linux:
    @echo "🐧 Running Flutter app on Linux..."
    flutter run -d linux

# Run Flutter app on Windows desktop
run-windows:
    @echo "🪟 Running Flutter app on Windows..."
    flutter run -d windows

# List all available devices
devices:
    @echo "📱 Available devices:"
    flutter devices

# Build Flutter app for mobile and desktop platforms
build-flutter:
    @echo "🏗️ Building Flutter for mobile and desktop platforms..."
    flutter build apk
    flutter build ios
    flutter build macos

# Run Flutter analyzer
analyze:
    @echo "🔍 Running Flutter analyzer..."
    flutter analyze



# Format Dart code
format-dart:
    @echo "💅 Formatting Dart code..."
    dart format lib/ integration_test/

# Check Dart code formatting (CI-style check)
check-dart-format:
    @echo "🔍 Checking Dart code formatting..."
    dart format --set-exit-if-changed lib/ integration_test/

# Test Flutter code
test-flutter:
    @echo "🧪 Testing Flutter code..."
    @if [ -d "test" ]; then flutter test; else echo "No test directory found. Create tests in test/ directory."; fi

# Test integration tests
test-integration:
    @echo "🧪 Running integration tests..."
    flutter test integration_test/

# ==============================================================================
# CLEANING
# ==============================================================================

# Clean generated bridge files only
clean-bridge:
    @echo "🧹 Cleaning generated bridge files..."
    rm -f rust/src/frb_generated.rs
    rm -rf lib/src/rust/

# Clean Flutter build cache
clean-flutter:
    @echo "🧹 Cleaning Flutter build cache..."
    flutter clean

# Clean Rust build cache
clean-rust:
    @echo "🧹 Cleaning Rust build cache..."
    cd rust && cargo clean

# Clean everything (bridge files + flutter + rust)
clean-all: clean-bridge clean-flutter clean-rust
    @echo "✨ All clean!"

# ==============================================================================
# FORMATTING & LINTING
# ==============================================================================

# Format all code (Rust + Dart)
format: format-rust format-dart

# Lint all code (Rust + Dart)
lint: lint-rust analyze

# Fix common issues
fix:
    @echo "🔧 Fixing common issues..."
    cd rust && cargo fix --allow-dirty
    dart fix --apply

# ==============================================================================
# UTILITIES
# ==============================================================================

# Show project info and status
info:
    @echo "📊 White Noise Project Info"
    @echo "Flutter version:"
    @flutter --version
    @echo ""
    @echo "Rust version:"
    @rustc --version
    @echo ""
    @echo "Cargo version:"
    @cargo --version
    @echo ""
    @echo "Project dependencies status:"
    @echo "- Flutter deps:"
    @flutter pub deps --no-dev | head -10
    @echo "- Rust deps:"
    @cd rust && cargo tree --depth 1

# Reset everything to clean state
reset: clean-all deps regenerate
    @echo "🔄 Project reset complete!"

# Check if all tools are installed
doctor:
    @echo "🏥 Checking development environment..."
    @flutter doctor
    @echo ""
    @echo "Checking Rust installation:"
    @rustc --version || echo "❌ Rust not installed"
    @cargo --version || echo "❌ Cargo not installed"
    @echo ""
    @echo "Checking flutter_rust_bridge_codegen:"
    @flutter_rust_bridge_codegen --version || echo "❌ flutter_rust_bridge_codegen not installed"

# Generate a fresh project setup (for new developers)
setup: doctor clean-all deps regenerate build-rust-debug
    @echo "🎉 Setup complete! Run 'just run' to start the app."
