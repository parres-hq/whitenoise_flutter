#!/bin/bash

# Build script for Android targets
set -e  # Exit on any error

echo "🚀 Building Rust library for Android targets..."

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

# Set Android NDK path
NDK_PATH="/Users/featuremindnigerialimited1/Library/Android/sdk/ndk/27.0.12077973"
export ANDROID_NDK_HOME="$NDK_PATH"
export PATH="$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH"

# Check if required tools are installed
print_step "Checking development environment"
if ! command -v rustup &> /dev/null; then
    print_error "Rustup is not installed or not in PATH"
    exit 1
fi

# Add Android targets if not already added
print_step "Adding Android targets to Rust"
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add i686-linux-android
rustup target add x86_64-linux-android

print_success "Android targets added to Rust"

# Create output directories if they don't exist
print_step "Creating output directories"
mkdir -p android/app/src/main/jniLibs/arm64-v8a
mkdir -p android/app/src/main/jniLibs/armeabi-v7a
mkdir -p android/app/src/main/jniLibs/x86
mkdir -p android/app/src/main/jniLibs/x86_64

# Build for each Android architecture
print_step "Building for Android architectures"
cd rust

# aarch64 (arm64-v8a)
print_step "Building for aarch64 (arm64-v8a)"
cargo build --target aarch64-linux-android --release
cp target/aarch64-linux-android/release/librust_lib_whitenoise.so ../android/app/src/main/jniLibs/arm64-v8a/
print_success "Built for aarch64 (arm64-v8a)"

# armv7 (armeabi-v7a)
print_step "Building for armv7 (armeabi-v7a)"
cargo build --target armv7-linux-androideabi --release
cp target/armv7-linux-androideabi/release/librust_lib_whitenoise.so ../android/app/src/main/jniLibs/armeabi-v7a/
print_success "Built for armv7 (armeabi-v7a)"

# i686 (x86)
print_step "Building for i686 (x86)"
cargo build --target i686-linux-android --release
cp target/i686-linux-android/release/librust_lib_whitenoise.so ../android/app/src/main/jniLibs/x86/
print_success "Built for i686 (x86)"

# x86_64 (x86_64)
print_step "Building for x86_64 (x86_64)"
cargo build --target x86_64-linux-android --release
cp target/x86_64-linux-android/release/librust_lib_whitenoise.so ../android/app/src/main/jniLibs/x86_64/
print_success "Built for x86_64 (x86_64)"

cd ..

print_success "All Rust libraries built and copied to Android project"
print_success "Android build completed successfully!"
print_success "You can now run 'flutter run' to test the app on Android"
