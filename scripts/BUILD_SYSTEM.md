# Build System for White Noise

This document describes the unified build system for White Noise. The system supports multiple build modes, quality checks (analysis and tests), and optional versioned outputs with organized directory structures.

## Features

- **Unified Build Script**: Single `build.sh` replacing multiple overlapping scripts
- **Quality Gates**: Code analysis and tests run before builds to catch issues early
- **Flexible Build Modes**: Quick, standard, and full builds with different trade-offs
- **Platform Selection**: Build Android, iOS, or both
- **Split-per-ABI**: Optimized Android APKs for different architectures
- **Versioned Outputs**: Optional organized directory structure with version information
- **Early Failure**: Stops immediately if analysis or tests fail

## Versioned Output Files

When using `--versioned`, files include version information from `pubspec.yaml`. For example, with version `0.1.3+4`:

- **Android ARM64** (Primary): `whitenoise-0.1.3-arm64-v8a.apk`
- **Android x86_64** (Emulator): `whitenoise-0.1.3-x86_64.apk`
- **iOS**: `whitenoise-0.1.3.ipa`

## Build Scripts

### Unified Build Script

**`./scripts/build.sh`** - The main build script with comprehensive options

```bash
# Build both platforms with versioned output
./scripts/build.sh --versioned

# Build only Android
./scripts/build.sh --android

# Build only iOS
./scripts/build.sh --ios

# Quick development build (skips analysis and tests)
./scripts/build.sh --quick --android

# Full build with analysis and tests
./scripts/build.sh --full --versioned

# Build with tests (but not full clean)
./scripts/build.sh --android --with-tests

# Debug builds
./scripts/build.sh --debug --android
```

### Platform-Specific Scripts

**`./scripts/build_android.sh`** - Android Rust library build (called by main script)
**`./scripts/build_ios.sh`** - iOS-specific build with versioning support

```bash
# Build iOS app bundle
./scripts/build_ios.sh

# Build iOS IPA (requires code signing)
./scripts/build_ios.sh --ipa

# Build debug version
./scripts/build_ios.sh --debug
```

## Output Structure

Versioned builds are organized in a structured output directory:

```
build/releases/v0.1.3/
├── whitenoise-0.1.3-arm64-v8a.apk        # Primary Android APK
├── whitenoise-0.1.3-x86_64.apk           # Android emulator APK
├── whitenoise-0.1.3.ipa                  # iOS app
└── build_info.txt                        # Build metadata
```

The `build_info.txt` file contains:
- Version information
- Build date and git information
- List of generated files

## Version Configuration

Version information is read from `pubspec.yaml`:

```yaml
version: 0.1.3+4
```

Where:
- `0.1.3` is the semantic version (versionName/CFBundleShortVersionString)
- `4` is the build number (versionCode/CFBundleVersion)

## Android Configuration

### Split-per-ABI Builds

The Android build system uses Flutter's `--split-per-abi` flag to create optimized APKs for each architecture:

- **ARM64-v8a**: Primary target for modern devices (64-bit ARM)
- **x86_64**: For Android emulators and x86_64 devices

This results in smaller APK sizes since each APK only contains the native libraries for its target architecture.

### Build Process

1. **Rust Library Build**: `./scripts/build_android.sh` compiles Rust code for both architectures:
   ```bash
   cargo build --target aarch64-linux-android --release
   cargo build --target x86_64-linux-android --release
   ```

2. **Flutter Build**: Uses `--split-per-abi` to create separate APKs:
   ```bash
   flutter build apk --split-per-abi --release
   ```

3. **Output Organization**: Build scripts copy and rename APKs with version information:
   - `app-arm64-v8a-release.apk` → `whitenoise-0.1.3-arm64-v8a.apk`
   - `app-x86_64-release.apk` → `whitenoise-0.1.3-x86_64.apk`

## iOS Configuration

iOS builds use the standard Flutter build process, and the versioned naming is handled by the build scripts when copying/organizing the output files.

## Build Process

The unified build system follows this sequence:

1. **Environment Checks**: Verify Flutter and required tools are available
2. **Dependency Management**: Get Flutter dependencies
3. **Code Generation**: Generate flutter_rust_bridge code
4. **Quality Gates** (unless `--quick`):
   - **Code Analysis**: `flutter analyze` (fails fast if issues found)
   - **Tests** (if enabled): Rust tests (`cargo test`) + Flutter tests (`flutter test`)
5. **Platform Builds**:
   - **Android**: Rust library build → Flutter APK with `--split-per-abi`
   - **iOS**: Flutter IPA or app bundle
6. **Output Organization** (if `--versioned`): Copy files to organized directory structure

## Build Modes

- **Quick** (`--quick`): Skip analysis and tests for fast iteration
- **Standard**: Run analysis, skip tests by default
- **Full** (`--full`): Run analysis, tests, and complete clean
- **With Tests** (`--with-tests`): Force tests even in standard mode

## Usage Examples

### Release Build for Distribution

```bash
# Clean build with versioned outputs for both platforms
./scripts/build.sh --versioned
```

### Quick Development Builds

```bash
# Quick Android build (faster iteration)
./scripts/build.sh --quick --android

# Quick iOS build
./scripts/build.sh --quick --ios
```

### Production Builds

```bash
# Full build with analysis, tests, and versioned output
./scripts/build.sh --full --versioned

# Android-only production build with tests
./scripts/build.sh --android --versioned --with-tests
```

### CI/CD Integration

```bash
# For automated builds
./scripts/build.sh --android --versioned --output-dir "dist/android"
```

## Benefits

1. **Easy Version Tracking**: File names clearly indicate the version
2. **Organized Releases**: Each version gets its own directory
3. **Build Information**: Automatic generation of build metadata
4. **Backward Compatibility**: Existing scripts still work
5. **CI/CD Ready**: Scriptable with clear options

## Notes

- iOS IPA creation requires proper code signing configuration
- Debug builds are supported but IPA creation for debug requires additional setup
- The system automatically creates the output directory structure
- Git information is included in build metadata when available
- All scripts include colored output for better readability
