#!/bin/bash

# Build script for iOS with versioned output
set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "iOS builds are only supported on macOS"
    exit 1
fi

print_step "🍎 Building iOS app for White Noise"

# Parse command line arguments
BUILD_TYPE="release"
CREATE_IPA=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            BUILD_TYPE="debug"
            shift
            ;;
        --ipa)
            CREATE_IPA=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --debug           Build debug version instead of release"
            echo "  --ipa             Create IPA file (requires proper code signing)"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Extract version information from pubspec.yaml
VERSION_LINE=$(grep "^version:" pubspec.yaml)
if [ -z "$VERSION_LINE" ]; then
    print_error "Could not find version in pubspec.yaml"
    exit 1
fi

# Extract version number and build number
FULL_VERSION=$(echo "$VERSION_LINE" | sed 's/version: //' | tr -d ' ')
VERSION_NAME=$(echo "$FULL_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$FULL_VERSION" | cut -d'+' -f2)

print_info "Version: $VERSION_NAME"
print_info "Build Number: $BUILD_NUMBER"
print_info "Build Type: $BUILD_TYPE"

# Create versioned output directory
OUTPUT_DIR="build/releases/v$VERSION_NAME"
mkdir -p "$OUTPUT_DIR"

# Clean previous builds
print_step "🧹 Cleaning previous builds"
flutter clean

# Get dependencies
print_step "📦 Getting Flutter dependencies"
flutter pub get

# Generate flutter_rust_bridge code
print_step "🔧 Generating flutter_rust_bridge code"
flutter_rust_bridge_codegen generate

# Build iOS app
if [ "$CREATE_IPA" = true ]; then
    if [ "$BUILD_TYPE" = "release" ]; then
        print_step "📱 Building iOS IPA (Release)"
        flutter build ipa --release --verbose

        # Find the generated IPA file and copy it with versioned name
        IPA_PATH=$(find build/ios/archive -name "*.ipa" -type f | head -n 1)
        if [ -n "$IPA_PATH" ]; then
            cp "$IPA_PATH" "$OUTPUT_DIR/whitenoise-${VERSION_NAME}-${BUILD_NUMBER}.ipa"
            print_success "iOS IPA copied to: $OUTPUT_DIR/whitenoise-${VERSION_NAME}-${BUILD_NUMBER}.ipa"
        else
            print_error "IPA file not found. Check code signing configuration."
            exit 1
        fi
    else
        print_warning "Debug IPA creation requires additional Xcode configuration"
        print_info "Building iOS app bundle instead..."
        flutter build ios --debug --verbose
        print_success "iOS debug app bundle built successfully"
    fi
else
    print_step "📱 Building iOS app bundle ($BUILD_TYPE)"
    if [ "$BUILD_TYPE" = "release" ]; then
        flutter build ios --release --verbose
    else
        flutter build ios --debug --verbose
    fi
    print_success "iOS app bundle built successfully"
    print_info "App bundle location: build/ios/iphoneos/Runner.app"
    print_info "To create an IPA, use: $0 --ipa"
fi

print_step "🎉 iOS build completed successfully!"

if [ "$CREATE_IPA" = true ] && [ -f "$OUTPUT_DIR/whitenoise-${VERSION_NAME}-${BUILD_NUMBER}.ipa" ]; then
    print_info "IPA file: $OUTPUT_DIR/whitenoise-${VERSION_NAME}-${BUILD_NUMBER}.ipa"
fi
