#!/bin/bash

# Fix Project File - Remove embedded find commands
# This script will search for and remove any embedded find commands in the project file

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

# Create backup
cp "$PROJECT_PATH" "${PROJECT_PATH}.backup"

echo "🔧 Removing find commands from project file..."

# Use sed to replace find commands with echo commands
sed -i '' 's/find \"\${BUILT_PRODUCTS_DIR}\"/echo \"Sandbox-safe: Not using find command\"/g' "$PROJECT_PATH"

echo "✨ Project file updated successfully!"
echo "📝 Please restart Xcode completely for changes to take effect."
exit 0 