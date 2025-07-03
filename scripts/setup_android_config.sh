#!/bin/bash

# Script to generate Cargo config for Android builds
set -e

echo "🔧 Setting up Android Cargo configuration..."

# Function to print colored output
print_success() {
    echo -e "\033[1;32m✅ $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m❌ $1\033[0m"
}

# Detect host OS for NDK toolchain path
case "$(uname -s)" in
    Darwin*)    HOST_TAG="darwin-x86_64" ;;
    Linux*)     HOST_TAG="linux-x86_64" ;;
    MINGW*|CYGWIN*|MSYS*) HOST_TAG="windows-x86_64" ;;
    *)          print_error "Unsupported host OS: $(uname -s)"; exit 1 ;;
esac

# Auto-detect Android NDK
if [ -z "$ANDROID_NDK_HOME" ]; then
    if [ -n "$ANDROID_HOME" ]; then
        NDK_DIR="$ANDROID_HOME/ndk"
        if [ -d "$NDK_DIR" ]; then
            NDK_VERSION=$(ls "$NDK_DIR" | sort -V | tail -n 1)
            if [ -n "$NDK_VERSION" ]; then
                ANDROID_NDK_HOME="$NDK_DIR/$NDK_VERSION"
            fi
        fi
    fi
fi

if [ -z "$ANDROID_NDK_HOME" ] || [ ! -d "$ANDROID_NDK_HOME" ]; then
    print_error "Android NDK not found. Please set ANDROID_NDK_HOME environment variable"
    exit 1
fi

# Create .cargo directory if it doesn't exist
mkdir -p rust/.cargo

# Generate config.toml
cat > rust/.cargo/config.toml << EOF
[target.aarch64-linux-android]
ar = "${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${HOST_TAG}/bin/llvm-ar"
linker = "${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${HOST_TAG}/bin/aarch64-linux-android33-clang"

[target.armv7-linux-androideabi]
ar = "${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${HOST_TAG}/bin/llvm-ar"
linker = "${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${HOST_TAG}/bin/armv7a-linux-androideabi33-clang"

[target.i686-linux-android]
ar = "${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${HOST_TAG}/bin/llvm-ar"
linker = "${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${HOST_TAG}/bin/i686-linux-android33-clang"

[target.x86_64-linux-android]
ar = "${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${HOST_TAG}/bin/llvm-ar"
linker = "${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/${HOST_TAG}/bin/x86_64-linux-android33-clang"
EOF

print_success "Generated Cargo config for host: $HOST_TAG"
print_success "Using Android NDK: $ANDROID_NDK_HOME" 