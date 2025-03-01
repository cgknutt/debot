#!/bin/bash

# Comprehensive Fix - Remove ALL embedded find commands from project
# This script is more aggressive and handles multiple patterns

echo "🔍 Searching for project file..."

# Look for the project.pbxproj file
PROJECT_FILES=(
    "debot.xcodeproj/project.pbxproj"
    "debot/debot.xcodeproj/project.pbxproj"
)

PROJECT_PATH=""
for file in "${PROJECT_FILES[@]}"; do
    if [ -f "$file" ]; then
        PROJECT_PATH="$file"
        break
    fi
done

if [ -z "$PROJECT_PATH" ]; then
    echo "❌ Could not find project file!"
    exit 1
fi

echo "✅ Found project file at: $PROJECT_PATH"
echo "📦 Making backup of project file..."

# Create backup with timestamp
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_PATH="${PROJECT_PATH}.backup.${TIMESTAMP}"
cp "$PROJECT_PATH" "$BACKUP_PATH"

echo "🔧 Removing ALL find commands from project file..."

# Look for common find patterns - each sed command handles a different pattern
sed -i '' 's/find \"\${BUILT_PRODUCTS_DIR}\"/echo \"Sandbox-safe: Not using find command\"/g' "$PROJECT_PATH"
sed -i '' 's/find \"\${SRCROOT}\"/echo \"Sandbox-safe: Not using find command\"/g' "$PROJECT_PATH"
sed -i '' 's/find \"\${PROJECT_DIR}\"/echo \"Sandbox-safe: Not using find command\"/g' "$PROJECT_PATH"
sed -i '' 's/find \"\${PRODUCT_DIR}\"/echo \"Sandbox-safe: Not using find command\"/g' "$PROJECT_PATH"
sed -i '' 's/find \"\${CONTENTS_FOLDER_PATH}\"/echo \"Sandbox-safe: Not using find command\"/g' "$PROJECT_PATH"
sed -i '' 's/find \"\${TARGET_BUILD_DIR}\"/echo \"Sandbox-safe: Not using find command\"/g' "$PROJECT_PATH"
sed -i '' 's/find \$(/echo "Sandbox-safe: Not using find command" #/g' "$PROJECT_PATH"
sed -i '' 's/find \\"/echo "Sandbox-safe: Not using find command" #/g' "$PROJECT_PATH"
sed -i '' 's/find "/echo "Sandbox-safe: Not using find command" #/g' "$PROJECT_PATH"
sed -i '' 's/`find /`echo "Sandbox-safe: Not using find command" #/g' "$PROJECT_PATH"
sed -i '' 's/$(find /$(echo "Sandbox-safe: Not using find command" #/g' "$PROJECT_PATH"

echo "🚫 Removing any build phase scripts that might use find..."
# This is more aggressive - it will find any script phases with find and comment them out
grep -l "find" "$PROJECT_PATH" > /dev/null && 
sed -i '' '/shellScript.*find/s/shellScript.*/shellScript = "echo \\"Sandbox-safe: Disabled find commands\\"";/g' "$PROJECT_PATH"

echo "✨ Project file updated comprehensively!"
echo "📝 Please restart Xcode completely, clean build folder, and try again."
echo "💾 Backup saved to: $BACKUP_PATH"
exit 0 