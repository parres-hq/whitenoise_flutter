#!/bin/bash

# Script to set up Android build environment for Rust
set -e  # Exit on any error

echo "🚀 Setting up Android build environment for Rust..."

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

# Get Android SDK path from Flutter
print_step "Detecting Android SDK path"
ANDROID_SDK_PATH=$(flutter config --machine | grep "androidSdkPath" | cut -d'"' -f4)

if [ -z "$ANDROID_SDK_PATH" ]; then
    print_error "Could not detect Android SDK path"
    exit 1
fi

print_success "Android SDK found at: $ANDROID_SDK_PATH"

# Find the latest NDK version
print_step "Finding NDK version"
NDK_VERSION=$(ls -1 "$ANDROID_SDK_PATH/ndk" | sort -V | tail -1)

if [ -z "$NDK_VERSION" ]; then
    print_warning "No NDK found, checking legacy location"
    NDK_VERSION=$(ls -1 "$ANDROID_SDK_PATH/ndk-bundle" 2>/dev/null || echo "")
    if [ -z "$NDK_VERSION" ]; then
        print_error "No NDK found. Please install NDK using Android Studio."
        exit 1
    else
        NDK_PATH="$ANDROID_SDK_PATH/ndk-bundle"
    fi
else
    NDK_PATH="$ANDROID_SDK_PATH/ndk/$NDK_VERSION"
fi

print_success "Using NDK version: $NDK_VERSION at $NDK_PATH"

# Create .cargo/config.toml with Android targets
print_step "Creating Cargo config for Android targets"
mkdir -p rust/.cargo
cat > rust/.cargo/config.toml << EOF
[target.aarch64-linux-android]
ar = "$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-ar"
linker = "$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android33-clang"

[target.armv7-linux-androideabi]
ar = "$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-ar"
linker = "$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/armv7a-linux-androideabi33-clang"

[target.i686-linux-android]
ar = "$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-ar"
linker = "$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/i686-linux-android33-clang"

[target.x86_64-linux-android]
ar = "$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-ar"
linker = "$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/x86_64-linux-android33-clang"
EOF

print_success "Created Cargo config for Android targets"

# Add Android targets to Rust
print_step "Adding Android targets to Rust"
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add i686-linux-android
rustup target add x86_64-linux-android

print_success "Android targets added to Rust"

# Set environment variables for the build
print_step "Setting up environment variables"
export ANDROID_NDK_HOME="$NDK_PATH"
export PATH="$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH"

print_success "Environment variables set"
print_success "Android build environment setup complete!"
print_warning "Now run 'flutter build apk' or 'flutter run' to build your app with the Rust library"
