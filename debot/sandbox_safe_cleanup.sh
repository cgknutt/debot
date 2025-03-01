#!/bin/bash

# Sandbox Safe Cleanup Script
# This script avoids using the 'find' command which triggers sandbox permission errors
# It uses direct path references instead

echo "🧹 Starting sandbox-safe cleanup..."

# Get environment variables
APP_PATH="${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}"
if [ -z "$APP_PATH" ]; then
    # Fallback for manual execution
    echo "⚠️ Running in fallback mode (script executed directly)"
    APP_PATH="$CONFIGURATION_BUILD_DIR/$EXECUTABLE_FOLDER_PATH"
fi

echo "📱 App path: $APP_PATH"

# Check if Info.plist exists in standard location
if [ -f "$APP_PATH/Info.plist" ]; then
    echo "✅ Found main Info.plist at expected location"
    
    # List of common locations for duplicate Info.plist files
    DUPLICATE_PATHS=(
        "$APP_PATH/Frameworks/Info.plist"
        "$APP_PATH/PlugIns/Info.plist"
        "$APP_PATH/Watch/Info.plist"
        "$APP_PATH/debot/Info.plist"
        "$APP_PATH/Resources/Info.plist"
    )
    
    # Remove duplicates at known locations
    for duplicate in "${DUPLICATE_PATHS[@]}"; do
        if [ -f "$duplicate" ]; then
            echo "🗑️ Removing duplicate Info.plist at: $duplicate"
            rm "$duplicate"
        fi
    done
    
    # Same for README.md files
    README_PATHS=(
        "$APP_PATH/README.md"
        "$APP_PATH/Frameworks/README.md"
        "$APP_PATH/PlugIns/README.md"
        "$APP_PATH/Watch/README.md"
        "$APP_PATH/debot/README.md"
        "$APP_PATH/Resources/README.md"
    )
    
    for readme in "${README_PATHS[@]}"; do
        if [ -f "$readme" ]; then
            echo "🗑️ Removing README.md at: $readme"
            rm "$readme"
        fi
    done
else
    echo "⚠️ Main Info.plist not found at: $APP_PATH/Info.plist"
fi

echo "✨ Sandbox-safe cleanup complete!"
exit 0 