#!/bin/bash

# Unified build script for White Noise Flutter project
# Replaces build_release.sh and build_versioned_release.sh
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

# Show usage information
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Build Options:"
    echo "  --android         Build Android APK only"
    echo "  --ios             Build iOS app only"
    echo "  --debug           Build debug version (default: release)"
    echo ""
    echo "Output Options:"
    echo "  --versioned       Create versioned output with organized directory structure"
    echo "  --output-dir DIR  Custom output directory (only with --versioned)"
    echo ""
    echo "Build Modes:"
    echo "  --quick           Quick build (skip analysis and tests, minimal cleaning)"
    echo "  --full            Full build with analysis, tests, and complete clean"
    echo "  --with-tests      Run tests before building (default for --full)"
    echo "  --skip-tests      Skip tests even with --full"
    echo ""
    echo "Other Options:"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Build both platforms, release"
    echo "  $0 --android --versioned             # Android release with versioned output"
    echo "  $0 --ios --debug                     # iOS debug build"
    echo "  $0 --quick --android                 # Quick Android build"
    echo "  $0 --full --versioned               # Full build with tests and versioned output"
    echo "  $0 --android --with-tests           # Android build with tests"
}

# Default values
BUILD_ANDROID=false
BUILD_IOS=false
BUILD_TYPE="release"
VERSIONED_OUTPUT=false
QUICK_BUILD=false
FULL_BUILD=false
WITH_TESTS=false
SKIP_TESTS=false
CUSTOM_OUTPUT_DIR=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --android)
            BUILD_ANDROID=true
            shift
            ;;
        --ios)
            BUILD_IOS=true
            shift
            ;;
        --debug)
            BUILD_TYPE="debug"
            shift
            ;;
        --versioned)
            VERSIONED_OUTPUT=true
            shift
            ;;
        --output-dir)
            CUSTOM_OUTPUT_DIR="$2"
            shift 2
            ;;
        --quick)
            QUICK_BUILD=true
            shift
            ;;
        --full)
            FULL_BUILD=true
            shift
            ;;
        --with-tests)
            WITH_TESTS=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
done

# If no platform specified, build both
if [ "$BUILD_ANDROID" = false ] && [ "$BUILD_IOS" = false ]; then
    BUILD_ANDROID=true
    # Only build iOS on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        BUILD_IOS=true
    fi
fi

# Determine if we should run tests
RUN_TESTS=false
if [ "$FULL_BUILD" = true ] && [ "$SKIP_TESTS" = false ]; then
    RUN_TESTS=true
elif [ "$WITH_TESTS" = true ]; then
    RUN_TESTS=true
fi

print_step "🚀 Building White Noise Flutter project"
print_info "Build Type: $BUILD_TYPE"
print_info "Platforms: $([ "$BUILD_ANDROID" = true ] && echo -n "Android ")$([ "$BUILD_IOS" = true ] && echo -n "iOS")"
print_info "Versioned Output: $([ "$VERSIONED_OUTPUT" = true ] && echo "Yes" || echo "No")"
print_info "Run Tests: $([ "$RUN_TESTS" = true ] && echo "Yes" || echo "No")"

# Extract version information from pubspec.yaml
VERSION_LINE=$(grep "^version:" pubspec.yaml)
if [ -z "$VERSION_LINE" ]; then
    print_error "Could not find version in pubspec.yaml"
    exit 1
fi

# Extract version number only (no build number)
FULL_VERSION=$(echo "$VERSION_LINE" | sed 's/version: //' | tr -d ' ')
VERSION_NAME=$(echo "$FULL_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$FULL_VERSION" | cut -d'+' -f2)

print_info "Version: $VERSION_NAME"
print_info "Build Number: $BUILD_NUMBER"

# Set up output directory
if [ "$VERSIONED_OUTPUT" = true ]; then
    if [ -n "$CUSTOM_OUTPUT_DIR" ]; then
        OUTPUT_DIR="$CUSTOM_OUTPUT_DIR"
    else
        OUTPUT_DIR="build/releases/v$VERSION_NAME"
    fi
    mkdir -p "$OUTPUT_DIR"
    print_info "Output Directory: $OUTPUT_DIR"
fi

# Environment checks
print_step "🔍 Checking development environment"
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

if ! command -v flutter_rust_bridge_codegen &> /dev/null; then
    print_error "flutter_rust_bridge_codegen is not installed"
    print_warning "Install with: cargo install flutter_rust_bridge_codegen"
    exit 1
fi

print_success "Development environment ready"

# Clean builds
if [ "$QUICK_BUILD" = true ]; then
    print_step "🧹 Quick clean (bridge files only)"
    rm -f rust/src/frb_generated.rs
    rm -f lib/src/rust/api.dart
    rm -f lib/src/rust/frb_generated.dart
    rm -f lib/src/rust/frb_generated.io.dart
    rm -f lib/src/rust/frb_generated.web.dart
elif [ "$FULL_BUILD" = true ]; then
    print_step "🧹 Full clean (everything)"
    rm -f rust/src/frb_generated.rs
    rm -f lib/src/rust/api.dart
    rm -f lib/src/rust/frb_generated.dart
    rm -f lib/src/rust/frb_generated.io.dart
    rm -f lib/src/rust/frb_generated.web.dart
    flutter clean
    cd rust && cargo clean && cd ..
else
    print_step "🧹 Standard clean"
    flutter clean
fi

# Get dependencies
print_step "📦 Getting dependencies"
flutter pub get

# Generate flutter_rust_bridge code
print_step "🔧 Generating flutter_rust_bridge code"
flutter_rust_bridge_codegen generate

# Run analysis and tests before building (except for quick builds)
if [ "$QUICK_BUILD" != true ]; then
    print_step "📊 Running code analysis"
    if flutter analyze; then
        print_success "Code analysis passed"
    else
        print_error "Code analysis failed - please fix issues before building"
        exit 1
    fi

    # Run tests if requested
    if [ "$RUN_TESTS" = true ]; then
        print_step "🧪 Running tests"

        # Run Rust tests
        print_info "Running Rust tests..."
        cd rust
        if cargo test; then
            print_success "Rust tests passed"
        else
            print_error "Rust tests failed - please fix issues before building"
            cd ..
            exit 1
        fi
        cd ..

        # Run Flutter tests
        print_info "Running Flutter tests..."
        if flutter test; then
            print_success "Flutter tests passed"
        else
            print_error "Flutter tests failed - please fix issues before building"
            exit 1
        fi
    fi
fi

# Build Android
if [ "$BUILD_ANDROID" = true ]; then
    print_step "🤖 Building Android"

    # Build Rust library for Android
    print_info "Building Rust library for Android targets..."
    ./scripts/build_android.sh

    # Build APK with split-per-abi
    if [ "$BUILD_TYPE" = "release" ]; then
        flutter build apk --split-per-abi --release --verbose

        # Handle output files
        ARM64_APK_PATH="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
        X86_64_APK_PATH="build/app/outputs/flutter-apk/app-x86_64-release.apk"

        if [ "$VERSIONED_OUTPUT" = true ]; then
            # Copy with versioned names
            if [ -f "$ARM64_APK_PATH" ]; then
                cp "$ARM64_APK_PATH" "$OUTPUT_DIR/whitenoise-${VERSION_NAME}-arm64-v8a.apk"
                print_success "ARM64 APK: $OUTPUT_DIR/whitenoise-${VERSION_NAME}-arm64-v8a.apk"
            else
                print_error "ARM64 APK not found at: $ARM64_APK_PATH"
            fi

            if [ -f "$X86_64_APK_PATH" ]; then
                cp "$X86_64_APK_PATH" "$OUTPUT_DIR/whitenoise-${VERSION_NAME}-x86_64.apk"
                print_success "x86_64 APK: $OUTPUT_DIR/whitenoise-${VERSION_NAME}-x86_64.apk"
            else
                print_warning "x86_64 APK not found (normal if not building for emulators)"
            fi
        else
            # Show default locations
            if [ -f "$ARM64_APK_PATH" ]; then
                print_success "ARM64 APK (Primary): $ARM64_APK_PATH"
            else
                print_error "ARM64 APK not found at: $ARM64_APK_PATH"
            fi

            if [ -f "$X86_64_APK_PATH" ]; then
                print_success "x86_64 APK (Emulator): $X86_64_APK_PATH"
            else
                print_warning "x86_64 APK not found (normal if not building for emulators)"
            fi
        fi
    else
        flutter build apk --split-per-abi --debug --verbose

        ARM64_DEBUG_APK="build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk"
        if [ "$VERSIONED_OUTPUT" = true ] && [ -f "$ARM64_DEBUG_APK" ]; then
            cp "$ARM64_DEBUG_APK" "$OUTPUT_DIR/whitenoise-${VERSION_NAME}-arm64-v8a-debug.apk"
            print_success "ARM64 debug APK: $OUTPUT_DIR/whitenoise-${VERSION_NAME}-arm64-v8a-debug.apk"
        elif [ -f "$ARM64_DEBUG_APK" ]; then
            print_success "ARM64 debug APK: $ARM64_DEBUG_APK"
        else
            print_error "ARM64 debug APK not found"
        fi
    fi
fi

# Build iOS
if [ "$BUILD_IOS" = true ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_step "🍎 Building iOS"

        if [ "$BUILD_TYPE" = "release" ]; then
            # Try to build IPA, fall back to app bundle
            if flutter build ipa --release --verbose 2>/dev/null; then
                IPA_PATH=$(find build/ios/archive -name "*.ipa" -type f | head -n 1)
                if [ -n "$IPA_PATH" ] && [ "$VERSIONED_OUTPUT" = true ]; then
                    cp "$IPA_PATH" "$OUTPUT_DIR/whitenoise-${VERSION_NAME}.ipa"
                    print_success "iOS IPA: $OUTPUT_DIR/whitenoise-${VERSION_NAME}.ipa"
                elif [ -n "$IPA_PATH" ]; then
                    print_success "iOS IPA: $IPA_PATH"
                else
                    print_warning "IPA creation failed, building app bundle instead"
                    flutter build ios --release --verbose
                    print_success "iOS app bundle: build/ios/iphoneos/Runner.app"
                fi
            else
                print_warning "IPA creation failed, building app bundle instead"
                flutter build ios --release --verbose
                print_success "iOS app bundle: build/ios/iphoneos/Runner.app"
            fi
        else
            flutter build ios --debug --verbose
            print_success "iOS debug app bundle: build/ios/iphoneos/Runner.app"
        fi
    else
        print_warning "iOS builds are only supported on macOS. Skipping iOS build."
    fi
fi

# Create build info file for versioned builds
if [ "$VERSIONED_OUTPUT" = true ]; then
    print_step "📝 Creating build information file"
    cat > "$OUTPUT_DIR/build_info.txt" << EOF
White Noise Build Information
============================

Version: $VERSION_NAME
Build Number: $BUILD_NUMBER
Full Version: $FULL_VERSION
Build Type: $BUILD_TYPE
Build Date: $(date)
Git Commit: $(git rev-parse --short HEAD 2>/dev/null || echo "Unknown")
Git Branch: $(git branch --show-current 2>/dev/null || echo "Unknown")

Built Files:
EOF

    # List built files
    if [ "$BUILD_ANDROID" = true ]; then
        if [ "$BUILD_TYPE" = "release" ]; then
            if [ -f "$OUTPUT_DIR/whitenoise-${VERSION_NAME}-arm64-v8a.apk" ]; then
                echo "- whitenoise-${VERSION_NAME}-arm64-v8a.apk (Primary - ARM64)" >> "$OUTPUT_DIR/build_info.txt"
            fi
            if [ -f "$OUTPUT_DIR/whitenoise-${VERSION_NAME}-x86_64.apk" ]; then
                echo "- whitenoise-${VERSION_NAME}-x86_64.apk (Emulator)" >> "$OUTPUT_DIR/build_info.txt"
            fi
        else
            if [ -f "$OUTPUT_DIR/whitenoise-${VERSION_NAME}-arm64-v8a-debug.apk" ]; then
                echo "- whitenoise-${VERSION_NAME}-arm64-v8a-debug.apk (Debug - ARM64)" >> "$OUTPUT_DIR/build_info.txt"
            fi
        fi
    fi

    if [ "$BUILD_IOS" = true ] && [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -f "$OUTPUT_DIR/whitenoise-${VERSION_NAME}.ipa" ]; then
            echo "- whitenoise-${VERSION_NAME}.ipa" >> "$OUTPUT_DIR/build_info.txt"
        fi
    fi
fi

print_step "🎉 Build completed successfully!"

if [ "$VERSIONED_OUTPUT" = true ]; then
    print_success "All build artifacts are available in: $OUTPUT_DIR"
    print_info "Build information saved to: $OUTPUT_DIR/build_info.txt"
    echo ""
    print_info "Build artifacts:"
    ls -la "$OUTPUT_DIR"
else
    print_info "Build artifacts are in their default Flutter locations"
    if [ "$BUILD_ANDROID" = true ]; then
        print_info "Android APKs: build/app/outputs/flutter-apk/"
    fi
    if [ "$BUILD_IOS" = true ]; then
        print_info "iOS app: build/ios/iphoneos/Runner.app"
    fi
fi

echo ""
print_info "💡 Usage tips:"
echo "   • Use --versioned for organized release builds"
echo "   • Use --quick for faster development builds"
echo "   • Use --full for complete builds with analysis"
