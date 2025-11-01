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
# Usage: just when-apk [--keep-so-files]
when-apk *FLAGS: (build-apk-stg FLAGS)

# Build staging APK with modified package ID and app name
# Deletes the .so files after building (unless --keep-so-files flag is provided)
# Usage: just build-apk-stg [--keep-so-files]
build-apk-stg *FLAGS:
    @echo "🦫 Building staging APK..."
    @echo "📦 Step 1: Building Rust .so files for Android..."
    ./scripts/build_android.sh
    @echo "✅ Rust libraries built successfully"
    @echo "🔧 Step 2: Applying staging configuration..."
    @# Backup original files
    @cp android/app/build.gradle.kts android/app/build.gradle.kts.backup
    @cp android/app/src/main/AndroidManifest.xml android/app/src/main/AndroidManifest.xml.backup
    @cp android/app/src/main/kotlin/com/example/whitenoise/MainActivity.kt android/app/src/main/kotlin/com/example/whitenoise/MainActivity.kt.backup
    @# Apply staging changes
    @sed -i.tmp 's/namespace = "org.parres.whitenoise"/namespace = "org.parres.whitenoise_stg"/' android/app/build.gradle.kts && rm android/app/build.gradle.kts.tmp
    @sed -i.tmp 's/applicationId = "org.parres.whitenoise"/applicationId = "org.parres.whitenoise_stg"/' android/app/build.gradle.kts && rm android/app/build.gradle.kts.tmp
    @sed -i.tmp 's/android:label="White Noise"/android:label="[stg] White Noise"/' android/app/src/main/AndroidManifest.xml && rm android/app/src/main/AndroidManifest.xml.tmp
    @sed -i.tmp 's/package org.parres.whitenoise$$/package org.parres.whitenoise_stg/' android/app/src/main/kotlin/com/example/whitenoise/MainActivity.kt && rm android/app/src/main/kotlin/com/example/whitenoise/MainActivity.kt.tmp
    @echo "✅ Staging configuration applied"
    @echo "📱 Step 3: Building APK..."
    flutter build apk --release --target-platform android-arm64
    @echo "🔄 Step 4: Restoring original configuration..."
    @mv android/app/build.gradle.kts.backup android/app/build.gradle.kts
    @mv android/app/src/main/AndroidManifest.xml.backup android/app/src/main/AndroidManifest.xml
    @mv android/app/src/main/kotlin/com/example/whitenoise/MainActivity.kt.backup android/app/src/main/kotlin/com/example/whitenoise/MainActivity.kt
    @echo "✅ Original configuration restored"
    @# Clean up .so files unless --keep-so-files flag is provided
    @if echo "{{FLAGS}}" | grep -q "keep-so-files"; then \
        echo "🔒 Keeping .so files (--keep-so-files flag detected)"; \
    else \
        echo "🧹 Cleaning up .so files..."; \
        rm -rf android/app/src/main/jniLibs/arm64-v8a; \
        rm -rf android/app/src/main/jniLibs/armeabi-v7a; \
        rm -rf android/app/src/main/jniLibs/x86_64; \
        echo "✅ .so files cleaned up"; \
    fi
    @echo "🦫 Staging APK built successfully!"
    @echo "📦 APK location: build/app/outputs/flutter-apk/app-release.apk"

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
