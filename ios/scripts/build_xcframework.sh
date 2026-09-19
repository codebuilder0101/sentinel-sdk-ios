#!/bin/bash
set -e

# ==============================================================================
# Sentinel SDK - XCFramework Build Automation Script
# Produces a clean, compiled binary .xcframework for device & simulator
# ==============================================================================

SCHEME="SentinelSDK"
FRAMEWORK_NAME="SentinelSDK"
OUTPUT_DIR="../build"
ARCHIVE_IOS_SIM="$OUTPUT_DIR/archives/ios_simulator.xcarchive"
ARCHIVE_IOS_DEV="$OUTPUT_DIR/archives/ios_device.xcarchive"
XCFRAMEWORK_OUTPUT="$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"

echo "🧹 Cleaning previous build artifacts..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/archives"

echo "📱 Archiving for iOS Simulator (arm64, x86_64)..."
xcodebuild archive \
  -scheme "$SCHEME" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$ARCHIVE_IOS_SIM" \
  -derivedDataPath "$OUTPUT_DIR/DerivedData" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo "📲 Archiving for iOS Device (arm64)..."
xcodebuild archive \
  -scheme "$SCHEME" \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_IOS_DEV" \
  -derivedDataPath "$OUTPUT_DIR/DerivedData" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo "📦 Creating unified .xcframework..."
xcodebuild -create-xcframework \
  -framework "$ARCHIVE_IOS_DEV/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
  -framework "$ARCHIVE_IOS_SIM/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
  -output "$XCFRAMEWORK_OUTPUT"

echo "✅ Successfully built: $XCFRAMEWORK_OUTPUT"
