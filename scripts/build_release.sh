#!/bin/bash
set -e

echo "🚀 Building release APK for White Noise..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Generate flutter_rust_bridge code
echo "🔧 Generating flutter_rust_bridge code..."
flutter_rust_bridge_codegen generate

# Build Rust library for Android
echo "🦀 Building Rust library for Android..."
./scripts/build_android.sh

# Build release APK
echo "📱 Building release APK..."
flutter build apk --release --verbose

echo "✅ Release APK built successfully!"
echo "📍 APK location: build/app/outputs/flutter-apk/app-release.apk" 