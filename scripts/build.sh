#!/bin/bash

# Full build script for White Noise Flutter project
# This script performs a complete build from scratch

set -e  # Exit on any error

echo "🚀 Building White Noise Flutter project..."

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

# Check if required tools are installed
print_step "Checking development environment"
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

if ! command -v cargo &> /dev/null; then
    print_error "Rust/Cargo is not installed or not in PATH"
    exit 1
fi

if ! command -v flutter_rust_bridge_codegen &> /dev/null; then
    print_error "flutter_rust_bridge_codegen is not installed"
    print_warning "Install with: cargo install flutter_rust_bridge_codegen"
    exit 1
fi

print_success "All required tools are available"

# Clean everything first
print_step "Cleaning previous builds"
rm -f rust/src/frb_generated.rs
rm -f lib/src/rust/api.dart
rm -f lib/src/rust/frb_generated.dart
rm -f lib/src/rust/frb_generated.io.dart
rm -f lib/src/rust/frb_generated.web.dart

flutter clean
cd rust && cargo clean && cd ..

print_success "Cleaned all build artifacts"

# Install/update dependencies
print_step "Installing dependencies"
cd rust && cargo fetch && cd ..
flutter pub get

print_success "Dependencies installed"

# Generate flutter_rust_bridge code
print_step "Generating flutter_rust_bridge code"
flutter_rust_bridge_codegen generate

print_success "Bridge code generated"

# Build Rust library
print_step "Building Rust library"
cd rust
cargo check
cargo build
cd ..

print_success "Rust library built"

# Run analysis
print_step "Running code analysis"
flutter analyze

# Check if there are any analysis issues
if [ $? -ne 0 ]; then
    print_warning "Flutter analyzer found issues - please review them"
else
    print_success "Code analysis passed"
fi

# Optional: Run tests
if [ "$1" = "--with-tests" ]; then
    print_step "Running tests"
    cd rust && cargo test && cd ..
    flutter test
    print_success "All tests passed"
fi

echo -e "\n\033[1;32m🎉 Build completed successfully!\033[0m"
echo -e "\033[1;33m💡 Next steps:\033[0m"
echo -e "   • Run 'flutter run' to start the app"
echo -e "   • Use 'just dev' for quick development iteration"
echo -e "   • Use 'just --list' to see all available commands"
