#!/bin/bash

# Script specifically for fixing the Info.plist duplication issue
echo "🔍 Fixing Info.plist duplication issue..."

# Set the correct project path based on current location
PROJECT_PATH="debot.xcodeproj/project.pbxproj"
if [ ! -f "$PROJECT_PATH" ]; then
    echo "❌ Error: Could not find project file at $PROJECT_PATH"
    exit 1
fi

# Backup the project file
BACKUP_PATH="${PROJECT_PATH}.infoplist.bak"
cp "$PROJECT_PATH" "$BACKUP_PATH"
echo "📋 Created backup at $BACKUP_PATH"

# Find all references to Info.plist in the project file
echo "Finding Info.plist references in project file..."
grep -n "Info\.plist\|GENERATE_INFOPLIST_FILE\|INFOPLIST_FILE" "$PROJECT_PATH" | cat

# Specific fix for Info.plist duplication
echo "Applying targeted fixes..."

# 1. Remove any Info.plist from Copy Bundle Resources phase
sed -i.tmp '/PBXResourcesBuildPhase/,/);/ s/Info\.plist.*,//g' "$PROJECT_PATH"

# 2. Fix the GENERATE_INFOPLIST_FILE setting - replace incorrect path values with YES
sed -i.tmp 's/GENERATE_INFOPLIST_FILE = ".*";/GENERATE_INFOPLIST_FILE = YES;/g' "$PROJECT_PATH"

# 3. Add INFOPLIST_FILE and GENERATE_INFOPLIST_FILE to debug configuration
perl -i.tmp -pe '
    if (/Debug \*\/ = {/) {
        $_ .= "\n\t\t\t\tGENERATE_INFOPLIST_FILE = YES;\n\t\t\t\tINFOPLIST_FILE = \"debot/Info.plist\";\n";
    }
' "$PROJECT_PATH"

# 4. Add INFOPLIST_FILE and GENERATE_INFOPLIST_FILE to release configuration
perl -i.tmp -pe '
    if (/Release \*\/ = {/) {
        $_ .= "\n\t\t\t\tGENERATE_INFOPLIST_FILE = YES;\n\t\t\t\tINFOPLIST_FILE = \"debot/Info.plist\";\n";
    }
' "$PROJECT_PATH"

# 5. Remove any references to processed Info.plist
sed -i.tmp '/processedInfoPlist/d' "$PROJECT_PATH"

# Clean up temporary files
rm -f "${PROJECT_PATH}.tmp"

echo "✅ Info.plist fix applied!"
echo ""
echo "Now please:"
echo "1. Clean your build folder (Product > Clean Build Folder)"
echo "2. Quit and restart Xcode"
echo "3. Build the project again"

exit 0 