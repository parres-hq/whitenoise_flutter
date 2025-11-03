# Justfile for White Noise Flutter project

# Default recipe - show available commands
default:
    @just --list

# Pre-commit checks: run the same checks as CI locally
precommit:
    just deps-flutter
    just deps-rust
    just fix
    just format
    just lint
    just test-flutter
    just test-rust
    @echo "✅ All pre-commit checks passed!"

# Pre-commit checks without auto-fixing (for releases)
precommit-check:
    just deps-flutter
    just deps-rust
    just check-rust-format
    just check-dart-format
    just lint
    just test-flutter
    just test-rust
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

# ==============================================================================
# RUST OPERATIONS
# ==============================================================================

# Build Rust library for development (debug)
build-rust-debug:
    @echo "🔨 Building Rust library (debug)..."
    cd rust && cargo build

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

# Run Flutter analyzer
analyze:
    @echo "🔍 Running Flutter analyzer..."
    flutter analyze --fatal-infos

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

# Test Flutter code with coverage and check diff coverage
check-flutter-coverage:
    @echo "🧪 Testing Flutter code with coverage..."
    flutter test --coverage
    @echo "📊 Checking coverage for changed files..."
    ./scripts/check_diff_coverage.sh

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

# ==============================================================================
# BUILDING
# ==============================================================================

# Build unversioned android release
android-build:
    @echo "🔨 Building unversioned android release..."
    ./scripts/build.sh --full --android
    @echo "🎉 Unversioned android release built successfully!"

# When APK? (alias for build-apk-stg)
when-apk: build-apk-stg

# Build staging APK with modified package ID and app name
# Backs up and restores all modified files (including .so files) to avoid git changes
build-apk-stg:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "🦫 Building staging APK..."
    
    # Define file paths
    GRADLE_FILE="android/app/build.gradle.kts"
    MANIFEST_FILE="android/app/src/main/AndroidManifest.xml"
    MAINACTIVITY_FILE="android/app/src/main/kotlin/com/example/whitenoise/MainActivity.kt"
    JNILIBS_DIR="android/app/src/main/jniLibs"
    JNILIBS_BACKUP_DIR="android/app/src/main/jniLibs.backup"
    
    # Cleanup function to restore original files
    cleanup() {
        local exit_code=$?
        
        # Always restore backups if they exist
        if [ -f "${GRADLE_FILE}.backup" ]; then
            mv "${GRADLE_FILE}.backup" "${GRADLE_FILE}"
            echo "✅ Restored ${GRADLE_FILE}"
        fi
        if [ -f "${MANIFEST_FILE}.backup" ]; then
            mv "${MANIFEST_FILE}.backup" "${MANIFEST_FILE}"
            echo "✅ Restored ${MANIFEST_FILE}"
        fi
        if [ -f "${MAINACTIVITY_FILE}.backup" ]; then
            mv "${MAINACTIVITY_FILE}.backup" "${MAINACTIVITY_FILE}"
            echo "✅ Restored ${MAINACTIVITY_FILE}"
        fi
        
        # Restore .so files if backup exists
        if [ -d "${JNILIBS_BACKUP_DIR}" ]; then
            rm -rf "${JNILIBS_DIR}"
            mv "${JNILIBS_BACKUP_DIR}" "${JNILIBS_DIR}"
            echo "✅ Restored ${JNILIBS_DIR}"
        fi
        
        # Remove any temporary sed files
        rm -f "${GRADLE_FILE}.tmp" "${MANIFEST_FILE}.tmp" "${MAINACTIVITY_FILE}.tmp"
        
        # Report status
        if [ $exit_code -ne 0 ]; then
            echo ""
            echo "❌ Build failed or interrupted - all files restored to original state"
            exit $exit_code
        fi
    }
    
    # Set trap to always run cleanup on exit, interrupt, or termination
    trap cleanup EXIT INT TERM
    
    # Step 1: Backup existing .so files (if they exist)
    if [ -d "${JNILIBS_DIR}" ]; then
        echo "💾 Backing up existing .so files..."
        cp -r "${JNILIBS_DIR}" "${JNILIBS_BACKUP_DIR}"
        echo "✅ .so files backed up"
    fi
    
    # Step 2: Build Rust .so files
    echo "📦 Step 2: Building Rust .so files for Android..."
    if ! ./scripts/build_android.sh; then
        echo "❌ Failed to build Rust libraries"
        exit 1
    fi
    echo "✅ Rust libraries built successfully"
    
    # Step 3: Apply staging configuration
    echo "🔧 Step 3: Applying staging configuration..."
    
    # Create backups
    cp "${GRADLE_FILE}" "${GRADLE_FILE}.backup"
    cp "${MANIFEST_FILE}" "${MANIFEST_FILE}.backup"
    cp "${MAINACTIVITY_FILE}" "${MAINACTIVITY_FILE}.backup"
    
    # Apply staging changes
    sed -i.tmp 's/namespace = "org.parres.whitenoise"/namespace = "org.parres.whitenoise_stg"/' "${GRADLE_FILE}" && rm "${GRADLE_FILE}.tmp"
    sed -i.tmp 's/applicationId = "org.parres.whitenoise"/applicationId = "org.parres.whitenoise_stg"/' "${GRADLE_FILE}" && rm "${GRADLE_FILE}.tmp"
    sed -i.tmp 's/android:label="White Noise"/android:label="[stg] White Noise"/' "${MANIFEST_FILE}" && rm "${MANIFEST_FILE}.tmp"
    sed -i.tmp 's/package org.parres.whitenoise$/package org.parres.whitenoise_stg/' "${MAINACTIVITY_FILE}" && rm "${MAINACTIVITY_FILE}.tmp"
    
    echo "✅ Staging configuration applied"
    
    # Step 4: Build APK
    echo "📱 Step 4: Building APK..."
    if ! flutter build apk --release --target-platform android-arm64; then
        echo "❌ Flutter build failed"
        exit 1
    fi
    
    # Verify APK was created
    if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        echo "❌ APK file not found after build"
        exit 1
    fi
    
    echo "🔄 Step 5: Restoring original configuration..."
    # Restoration happens automatically via cleanup trap (includes .so files)
    
    echo "🦫 Staging APK built successfully!"
    echo "📦 APK location: build/app/outputs/flutter-apk/app-release.apk"

# Check and build versioned release
release:
    @echo "🔨 Building versioned release..."
    @echo "🔍 Verifying working tree is clean..."
    @if ! git diff-index --quiet HEAD --; then \
        echo "❌ Working tree is not clean. Please commit or stash changes before release."; \
        git status --short; \
        exit 1; \
    fi
    @echo "✅ Working tree is clean"
    @echo "🔍 Verifying build script..."
    @if [ ! -f "scripts/build.sh" ]; then \
        echo "❌ Build script not found: scripts/build.sh"; \
        exit 1; \
    fi
    @if [ ! -x "scripts/build.sh" ]; then \
        echo "❌ Build script is not executable: scripts/build.sh"; \
        echo "💡 Run: chmod +x scripts/build.sh"; \
        exit 1; \
    fi
    @echo "✅ Build script verified"
    @echo "🎁 Building versioned release for Android and iOS..."
    ./scripts/build.sh --full --versioned
    @echo "🎉 Versioned release built successfully!"

# ==============================================================================
# LOGS
# ==============================================================================

# Tail the latest Rust log file produced by the app.
# Usage:
#   just rust-logs                # follow in real time (tail -f)
#   just rust-logs 500            # print last 500 lines and exit
# Works on macOS simulator and macOS app (container). Falls back to ~/Documents.
rust-logs lines='':
    @set -euo pipefail; \
    BUNDLE_ID=org.parres.whitenoise; \
    LINES='{{lines}}'; \
    if [ -z "$LINES" ]; then \
      echo "🔎 Locating latest Rust log and following in real time..."; \
    else \
      echo "🔎 Locating latest Rust log (last ${LINES} lines)..."; \
    fi; \
    CANDIDATES=""; \
    if command -v xcrun >/dev/null 2>&1; then \
      APP_CONTAINER="$(xcrun simctl get_app_container booted "$BUNDLE_ID" data 2>/dev/null || true)"; \
      if [ -n "$APP_CONTAINER" ] && [ -d "$APP_CONTAINER" ]; then \
        CANDIDATES="$CANDIDATES $APP_CONTAINER/Documents/whitenoise/logs/dev"; \
      fi; \
    fi; \
    CANDIDATES="$CANDIDATES $HOME/Library/Containers/$BUNDLE_ID/Data/Documents/whitenoise/logs/dev $HOME/Documents/whitenoise/logs/dev"; \
    latest=""; latest_mtime=0; \
    for d in $CANDIDATES; do \
      if [ -d "$d" ]; then \
        for f in "$d"/*; do \
          [ -f "$f" ] || continue; \
          m=$(stat -f "%m" "$f" 2>/dev/null || echo 0); \
          if [ "$m" -gt "$latest_mtime" ]; then latest_mtime="$m"; latest="$f"; fi; \
        done; \
      fi; \
    done; \
    if [ -n "$latest" ]; then \
      echo "Latest log file: $latest"; \
      if [ -z "$LINES" ]; then \
        tail -f "$latest"; \
      else \
        tail -n "$LINES" "$latest"; \
      fi; \
    else \
      echo "❌ No log files found. Ensure the app has run and produced logs."; \
      exit 1; \
    fi
