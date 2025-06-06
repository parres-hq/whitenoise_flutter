#!/bin/bash

# Development script for White Noise Flutter project
# This script is optimized for quick development iteration

set -e  # Exit on any error

echo "🔧 Development build for White Noise..."

# Function to print colored output
print_step() {
    echo -e "\n\033[1;34m=== $1 ===\033[0m"
}

print_success() {
    echo -e "\033[1;32m✅ $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m⚠️ $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m❌ $1\033[0m"
}

# Quick dependency check
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

if ! command -v cargo &> /dev/null; then
    print_error "Rust/Cargo is not installed or not in PATH"
    exit 1
fi

# Clean only bridge files (not full clean for faster iteration)
print_step "Cleaning bridge files"
rm -f rust/src/frb_generated.rs
rm -f lib/src/rust/api.dart
rm -f lib/src/rust/frb_generated.dart
rm -f lib/src/rust/frb_generated.io.dart
rm -f lib/src/rust/frb_generated.web.dart

print_success "Bridge files cleaned"

# Regenerate flutter_rust_bridge code
print_step "Regenerating flutter_rust_bridge code"
flutter_rust_bridge_codegen generate

print_success "Bridge code regenerated"

# Quick check of Rust code (don't build if not necessary)
print_step "Checking Rust code"
cd rust
cargo check
cd ..

print_success "Rust code is valid"

# Get Flutter dependencies if needed
print_step "Ensuring Flutter dependencies"
flutter pub get

print_success "Flutter dependencies ready"

# Optional: Run quick analysis
if [ "$1" = "--analyze" ]; then
    print_step "Running quick analysis"
    flutter analyze --no-fatal-infos
    print_success "Analysis complete"
fi

# Optional: Skip running the app
if [ "$1" = "--no-run" ]; then
    echo -e "\n\033[1;32m🎉 Development setup complete!\033[0m"
    echo -e "\033[1;33m💡 Run 'flutter run' to start the app when ready\033[0m"
    exit 0
fi

# Start Flutter app in debug mode
print_step "Starting Flutter app in debug mode"
print_success "Development environment ready"
echo -e "\033[1;33m💡 The app will start with hot reload enabled\033[0m"
echo -e "\033[1;33m💡 Press 'r' to hot reload, 'R' to hot restart, 'q' to quit\033[0m"

flutter run
