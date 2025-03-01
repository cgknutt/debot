#!/bin/bash

# This script deletes duplicate Info.plist files during the build process
# It needs to run both at the beginning and end of build

echo "📦 Removing any duplicate Info.plist files..."

# Remove Info.plist files from intermediate build directories
find "${BUILT_PRODUCTS_DIR}" -path "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Info.plist" -prune -o -name "Info.plist" -print -delete

# Keep only one Info.plist in the final app bundle
if [ -d "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}" ]; then
    # Count how many Info.plist files exist
    COUNT=$(find "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}" -name "Info.plist" | wc -l | tr -d '[:space:]')
    
    if [ "$COUNT" -gt 1 ]; then
        echo "⚠️ Found multiple Info.plist files in app bundle, keeping only one..."
        
        # Find all Info.plist files except the main one
        find "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}" -path "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Info.plist" -prune -o -name "Info.plist" -print -delete
    fi
fi

echo "✅ Duplicate Info.plist removal complete"
