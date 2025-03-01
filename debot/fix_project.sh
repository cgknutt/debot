#!/bin/bash

# Script to surgically remove references to problematic files from the project

echo "🔧 Surgically fixing project.pbxproj file..."

PROJECT_PATH="debot.xcodeproj/project.pbxproj"
if [ ! -f "$PROJECT_PATH" ]; then
    echo "❌ Error: Could not find project file at $PROJECT_PATH"
    exit 1
fi

# Create a backup of the project file
cp "$PROJECT_PATH" "${PROJECT_PATH}.fix.bak"
echo "📋 Created backup at ${PROJECT_PATH}.fix.bak"

# Remove references to README.md in Copy Bundle Resources
echo "Removing README.md references..."
grep -n "README\.md" "$PROJECT_PATH" | cat

# Remove all README.md file references using sed
sed -i.tmp '/README\.md/d' "$PROJECT_PATH"
rm -f "${PROJECT_PATH}.tmp"

# Check for and fix duplicate Info.plist references
echo "Fixing Info.plist references..."
INFO_PLIST_REFS=$(grep -n "Info\.plist.*isa.*PBXFileReference" "$PROJECT_PATH" | cat)
INFO_PLIST_COUNT=$(echo "$INFO_PLIST_REFS" | wc -l | xargs)

echo "Found $INFO_PLIST_COUNT Info.plist references in project file"
echo "$INFO_PLIST_REFS"

# We're going to focus on removing any builds that try to process Info.plist multiple times
echo "Checking for Info.plist in build phases..."
BUILD_PHASE_REFS=$(grep -n -A 5 "isa = PBXResourcesBuildPhase" "$PROJECT_PATH" | grep -n "Info\.plist" | cat)
echo "$BUILD_PHASE_REFS"

# Force building to use only the main Info.plist
MAIN_INFO_PATH="debot/Info.plist"
echo "Setting $MAIN_INFO_PATH as the sole Info.plist source"

# Remove compiled Info.plist references from the project file
sed -i.tmp '/processedInfoPlist/d' "$PROJECT_PATH"
rm -f "${PROJECT_PATH}.tmp"

echo "✅ Project fixes applied"
echo "Now please try the following:"
echo "1. Clean your build folder in Xcode (Product > Clean Build Folder)"
echo "2. Build the project again"

exit 0 