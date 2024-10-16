#!/bin/bash

# Build script for MenubarGPT main target only
# This avoids issues with empty test targets

echo "Building MenubarGPT (main target only)..."
xcodebuild -project MenubarGPT.xcodeproj -target MenubarGPT build

if [ $? -eq 0 ]; then
    echo "Build successful!"
else
    echo "Build failed!"
    exit 1
fi
# Build: add code signing options
