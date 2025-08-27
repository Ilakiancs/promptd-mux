#!/bin/bash

# MenubarGPT Build Script
# This script builds and runs the MenubarGPT application

set -e

PROJECT_NAME="MenubarGPT"
SCHEME_NAME="MenubarGPT"
BUILD_DIR="build"

echo "Building $PROJECT_NAME..."

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf "$BUILD_DIR"
xcodebuild clean -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME_NAME" > /dev/null 2>&1

# Build the project
echo "Building project..."
xcodebuild build \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -configuration Debug \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO

if [ $? -eq 0 ]; then
    echo "Build successful!"
    
    # Find the built app
    APP_PATH=$(find "$BUILD_DIR" -name "*.app" -type d | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "Built app found at: $APP_PATH"
        echo ""
        echo "To run the app manually:"
        echo "open \"$APP_PATH\""
        echo ""
        
        # Ask if user wants to run the app
        read -p "Would you like to run the app now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Launching $PROJECT_NAME..."
            open "$APP_PATH"
        fi
    else
        echo "Could not find built app"
        exit 1
    fi
else
    echo "Build failed"
    exit 1
fi
