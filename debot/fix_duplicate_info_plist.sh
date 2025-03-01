#!/bin/bash

# Script to fix the "Multiple commands produce Info.plist" error
echo "🔧 Fixing Multiple commands produce Info.plist error..."

# Set the correct project path based on current location
PROJECT_PATH="debot.xcodeproj/project.pbxproj"
if [ ! -f "$PROJECT_PATH" ]; then
    echo "❌ Error: Could not find project file at $PROJECT_PATH"
    exit 1
fi

# Backup the project file
BACKUP_PATH="${PROJECT_PATH}.duplicate.bak"
cp "$PROJECT_PATH" "$BACKUP_PATH"
echo "📋 Created backup at $BACKUP_PATH"

echo "🔍 Applying targeted fixes..."

# Create a temporary file with all the edits
TMP_FILE=$(mktemp)
cat "$PROJECT_PATH" > "$TMP_FILE"

# 1. Remove Info.plist from Copy Bundle Resources build phase
# This is crucial - we don't want to copy the Info.plist, just have one generated
perl -pi -e 's/(.*Info\.plist in Copy Bundle Resources.*)//g' "$TMP_FILE"
perl -pi -e 's/(.*Info\.plist in Resources.*)//g' "$TMP_FILE"
perl -pi -e 's/([0-9A-F]{24} \/\* Info\.plist \*\/.*)//g' "$TMP_FILE"

# 2. Make sure we only generate the Info.plist in ONE place
# First, disable all GENERATE_INFOPLIST_FILE settings
perl -pi -e 's/GENERATE_INFOPLIST_FILE = YES;/GENERATE_INFOPLIST_FILE = NO;/g' "$TMP_FILE"

# Then, enable it only in one target's Debug configuration
perl -pi -e 'if (/Debug \*\/ = \{/ && $once != 1) { $once = 1; $_ .= "\n\t\t\t\tGENERATE_INFOPLIST_FILE = YES;\n"; }' "$TMP_FILE"

# 3. Make sure INFOPLIST_FILE is consistently set to the same path
perl -pi -e 's/INFOPLIST_FILE = .*/INFOPLIST_FILE = "debot\/Info.plist";/g' "$TMP_FILE"

# 4. Clean up any duplicate or processed Info.plist references
perl -pi -e 's/.*processedInfoPlist.*//g' "$TMP_FILE"

# 5. Clean up any empty lines created by our removals
perl -pi -e 's/^\s*$//g' "$TMP_FILE"

# Move the updated file back
mv "$TMP_FILE" "$PROJECT_PATH"

echo "✅ Fix for duplicate Info.plist issue applied!"
echo ""
echo "Now please:"
echo "1. Clean your build folder (Product > Clean Build Folder)"
echo "2. Delete the DerivedData folder:"
echo "   rm -rf ~/Library/Developer/Xcode/DerivedData/debot-*"
echo "3. Quit and restart Xcode completely"
echo "4. Build your project again"

exit 0 