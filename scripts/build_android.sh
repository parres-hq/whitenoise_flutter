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

# Auto-detect Android SDK and NDK paths
print_step "Detecting Android SDK and NDK paths"

# Try to find Android SDK
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
    # Common Android SDK locations
    POSSIBLE_SDK_PATHS=(
        "$HOME/Library/Android/sdk"           # macOS default
        "$HOME/Android/Sdk"                   # Linux default
        "$HOME/AppData/Local/Android/Sdk"     # Windows default
        "/opt/android-sdk"                    # Linux alternative
    )

    for path in "${POSSIBLE_SDK_PATHS[@]}"; do
        if [ -d "$path" ]; then
            export ANDROID_HOME="$path"
            export ANDROID_SDK_ROOT="$path"
            print_success "Found Android SDK at: $path"
            break
        fi
    done
else
    export ANDROID_HOME="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
    export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
    print_success "Using Android SDK from environment: $ANDROID_HOME"
fi

if [ -z "$ANDROID_HOME" ]; then
    print_error "Android SDK not found. Please install Android SDK or set ANDROID_HOME environment variable"
    exit 1
fi

# Auto-detect NDK path
if [ -z "$ANDROID_NDK_HOME" ]; then
    # Look for NDK in the SDK directory
    NDK_DIR="$ANDROID_HOME/ndk"
    if [ -d "$NDK_DIR" ]; then
        # Find the latest NDK version
        NDK_VERSION=$(ls "$NDK_DIR" | sort -V | tail -n 1)
        if [ -n "$NDK_VERSION" ]; then
            export ANDROID_NDK_HOME="$NDK_DIR/$NDK_VERSION"
            print_success "Found NDK version $NDK_VERSION at: $ANDROID_NDK_HOME"
        fi
    fi
fi

if [ -z "$ANDROID_NDK_HOME" ] || [ ! -d "$ANDROID_NDK_HOME" ]; then
    print_error "Android NDK not found. Please install Android NDK or set ANDROID_NDK_HOME environment variable"
    print_error "You can install NDK through Android Studio SDK Manager"
    exit 1
fi

# Detect host OS for NDK toolchain path
case "$(uname -s)" in
    Darwin*)    HOST_TAG="darwin-x86_64" ;;
    Linux*)     HOST_TAG="linux-x86_64" ;;
    MINGW*|CYGWIN*|MSYS*) HOST_TAG="windows-x86_64" ;;
    *)          print_error "Unsupported host OS: $(uname -s)"; exit 1 ;;
esac

export PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin:$PATH"

# Set environment variables for ring crate and cc-rs
export CC_armv7_linux_androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin/armv7a-linux-androideabi33-clang"
export CXX_armv7_linux_androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin/armv7a-linux-androideabi33-clang++"
export AR_armv7_linux_androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin/llvm-ar"

# Check if required tools are installed
print_step "Checking development environment"
if ! command -v rustup &> /dev/null; then
    print_error "Rustup is not installed or not in PATH"
    exit 1
fi

# Generate Cargo config for current environment
print_step "Setting up Cargo configuration"
./scripts/setup_android_config.sh

# Add Android targets
print_step "Adding Android targets to Rust"
rustup target add aarch64-linux-android      # arm64-v8a (64-bit ARM)
rustup target add armv7-linux-androideabi    # armeabi-v7a (32-bit ARM)
rustup target add x86_64-linux-android       # x86_64 (64-bit Intel)
print_success "Android targets added to Rust"

# Create output directories
print_step "Creating output directories"
mkdir -p android/app/src/main/jniLibs/arm64-v8a
mkdir -p android/app/src/main/jniLibs/armeabi-v7a
mkdir -p android/app/src/main/jniLibs/x86_64

# Build for each Android architecture
print_step "Building for Android architectures"
cd rust

# aarch64 (arm64-v8a) - 64-bit ARM
print_step "Building for aarch64 (arm64-v8a)"
cargo build --target aarch64-linux-android --release --quiet
cp target/aarch64-linux-android/release/librust_lib_whitenoise.so ../android/app/src/main/jniLibs/arm64-v8a/
print_success "Built for aarch64 (arm64-v8a)"

# armv7 (armeabi-v7a) - 32-bit ARM
print_step "Building for armv7 (armeabi-v7a)"
cargo build --target armv7-linux-androideabi --release --quiet
cp target/armv7-linux-androideabi/release/librust_lib_whitenoise.so ../android/app/src/main/jniLibs/armeabi-v7a/
print_success "Built for armv7 (armeabi-v7a)"

# x86_64 - 64-bit Intel
print_step "Building for x86_64"
cargo build --target x86_64-linux-android --release --quiet
cp target/x86_64-linux-android/release/librust_lib_whitenoise.so ../android/app/src/main/jniLibs/x86_64/
print_success "Built for x86_64"

cd ..

print_success "All Rust libraries built and copied to Android project"
print_success "Android build completed successfully!"
print_success "You can now run 'flutter run' to test the app on Android"
