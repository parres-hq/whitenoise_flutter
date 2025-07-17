# 🛠 Android Build Setup for White Noise (Flutter + Rust)

This document explains how to set up Android builds for the White Noise Flutter project.
The Rust code lives in the rust/ subdirectory. The generated .so files are placed into android/app/src/main/jniLibs/<abi> during the build.

The build script will generate a .cargo/config.toml inside the rust/ directory to set up cross-compilation toolchains automatically.

## Prerequisites

1. **Android Studio** with Android SDK installed
2. **Android NDK** (can be installed through Android Studio SDK Manager)
3. **Rust** with `rustup` installed

## Environment Setup

The build scripts will automatically detect your Android SDK and NDK installations, but you can also set environment variables manually:

```bash
# Optional: Set these if auto-detection doesn't work
export ANDROID_HOME="/path/to/your/android/sdk"
export ANDROID_NDK_HOME="/path/to/your/android/ndk"
```

### Common Android SDK Locations

- **macOS**: `~/Library/Android/sdk`
- **Linux**: `~/Android/Sdk`
- **Windows**: `%LOCALAPPDATA%\Android\Sdk`

## Building for Android
### ✅ One-Time Setup (Required)

Before you can run the build scripts, make sure they’re executable:
```bash
chmod +x ./scripts/setup_android_config.sh
chmod +x ./scripts/build_android.sh
```
You only need to do this once per machine or after cloning the repo.

1. **Run the build script**:
   ```bash
   ./scripts/build_android.sh
   ```

2. **The script will automatically**:
   - Detect your Android SDK and NDK
   - Generate the appropriate Cargo configuration for your OS
   - Add required Rust targets
   - Build the Rust library for Android architectures
   - Copy the built libraries to the correct Android directories

3. **Run the Flutter app**:
   ```bash
   flutter run
   ```

## Supported Architectures

The build currently targets:
- `aarch64-linux-android` (ARM64 - most modern Android devices)
- `x86_64-linux-android` (x86_64 - emulators)

## Troubleshooting

### 📌 “Where is my .so?” tip
After building, you’ll find .so files in:

```
android/app/src/main/jniLibs/arm64-v8a/librust_lib_whitenoise.so
android/app/src/main/jniLibs/x86_64/librust_lib_whitenoise.so
```

### NDK Not Found
If you get "Android NDK not found":
1. Install NDK through Android Studio SDK Manager
2. Or set `ANDROID_NDK_HOME` environment variable manually

### SDK Not Found
If you get "Android SDK not found":
1. Install Android Studio
2. Or set `ANDROID_HOME` environment variable manually

### Build Failures
1. Make sure you have the latest Rust version: `rustup update`
2. Clean and rebuild: `cargo clean` in the `rust/` directory
3. Check that your NDK version is compatible (we use API level 33)

## Cross-Platform Support

The build scripts support:
- **macOS** (darwin-x86_64)
- **Linux** (linux-x86_64)  
- **Windows** (windows-x86_64)

The Cargo configuration is automatically generated for your platform. 