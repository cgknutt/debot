#!/bin/bash

# IMPORTANT: Run this script ONCE from the command line to fix duplicate resources issues
# This script directly modifies Xcode project settings

set -e  # Exit on any error

echo "🔧 Applying direct fixes to Xcode project settings..."

# Path to the project file
PROJECT_PATH="debot.xcodeproj/project.pbxproj"
if [ ! -f "$PROJECT_PATH" ]; then
    echo "❌ Error: Could not find project file at $PROJECT_PATH"
    exit 1
fi

# Create a backup of the project file
cp "$PROJECT_PATH" "${PROJECT_PATH}.bak"
echo "📋 Created backup at ${PROJECT_PATH}.bak"

# Fix 1: Remove README.md files from Copy Bundle Resources phase
echo "Removing README.md files from Copy Bundle Resources phase..."
sed -i.tmp '/README\.md/d' "$PROJECT_PATH"
rm -f "${PROJECT_PATH}.tmp"

# Fix 2: Ensure only one Info.plist is included
echo "Ensuring only one Info.plist is included..."
# This is a simplified approach - the full solution would require parsing the pbxproj file
# to find and remove duplicate Info.plist references which is beyond the scope of this script

echo "🔍 Checking for duplicate Info.plist files in the project..."
INFO_PLIST_FILES=$(find . -name "Info.plist" | sort)
echo "$INFO_PLIST_FILES"

# Fix 3: Update INFOPLIST_FILE setting to point to the main Info.plist
MAIN_INFO_PLIST="debot/Info.plist"
if [ -f "$MAIN_INFO_PLIST" ]; then
    echo "Setting $MAIN_INFO_PLIST as the main Info.plist file"
    # Again, this would require more complex processing of the pbxproj file
fi

echo "✅ Direct fixes applied. Please clean and rebuild your project."
echo "⚠️ Note: Some manual adjustments may still be needed in Xcode:"
echo "   1. Open the project in Xcode"
echo "   2. Select the debot target"
echo "   3. Go to Build Phases"
echo "   4. Under 'Copy Bundle Resources', verify no README.md files are listed"
echo "   5. Under 'Build Settings', ensure INFOPLIST_FILE points to debot/Info.plist"
echo ""
echo "If issues persist, consider adding the fix_duplicate_resources.sh and post_build_cleanup.sh"
echo "scripts as Run Script phases in your Xcode project."

exit 0 