#!/bin/bash

# This script renames a color asset in the Assets.xcassets folder
# from "Primary" to "AppPrimary"

echo "🔍 Searching for Assets.xcassets folder..."

# Possible paths for Assets.xcassets
ASSET_PATHS=(
    "debot/Assets.xcassets"
    "debot/debot/Assets.xcassets"
)

ASSET_PATH=""
for path in "${ASSET_PATHS[@]}"; do
    if [ -d "$path" ]; then
        ASSET_PATH="$path"
        break
    fi
done

if [ -z "$ASSET_PATH" ]; then
    echo "❌ Assets.xcassets folder not found!"
    exit 1
fi

echo "✅ Found Assets.xcassets at: $ASSET_PATH"

# Check if Primary.colorset exists
if [ -d "$ASSET_PATH/Primary.colorset" ]; then
    echo "✅ Found Primary.colorset"
    
    # Create AppPrimary.colorset by copying Primary.colorset
    echo "🔧 Creating AppPrimary.colorset..."
    cp -R "$ASSET_PATH/Primary.colorset" "$ASSET_PATH/AppPrimary.colorset"
    
    # Optional: Remove the old Primary.colorset
    # Uncomment the line below if you want to remove it
    # rm -rf "$ASSET_PATH/Primary.colorset"
    
    echo "✨ Color asset renamed successfully!"
else
    echo "❌ Primary.colorset not found in $ASSET_PATH"
    echo "Please manually create an AppPrimary color in your asset catalog."
fi

exit 0 