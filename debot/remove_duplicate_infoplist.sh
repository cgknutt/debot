#!/bin/bash

# Direct intervention script to prevent duplicate Info.plist files
echo "🔧 Adding direct removal script for duplicate Info.plist files..."

# Set the correct project path based on current location
PROJECT_PATH="debot.xcodeproj/project.pbxproj"
if [ ! -f "$PROJECT_PATH" ]; then
    echo "❌ Error: Could not find project file at $PROJECT_PATH"
    exit 1
fi

# First, create the deletion script
SCRIPT_PATH="remove_infoplist_duplicates.sh"
cat > "$SCRIPT_PATH" << 'EOL'
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
EOL

# Make the script executable
chmod +x "$SCRIPT_PATH"
echo "✅ Created executable script: $SCRIPT_PATH"

# Backup the project file
BACKUP_PATH="${PROJECT_PATH}.runscript.bak"
cp "$PROJECT_PATH" "$BACKUP_PATH"
echo "📋 Created backup at $BACKUP_PATH"

echo "🔍 Adding Run Script phase to project..."

# Now add a run script phase to the beginning and end of each target's build phases
# We'll need to identify the targets and their build phase sections

# Extract the project's main target section using grep and awk
TARGET_SECTION=$(grep -A 5 "targets = (" "$PROJECT_PATH" | grep -m 1 "targetName" | grep -o "[0-9A-F]\{24\}")
if [ -z "$TARGET_SECTION" ]; then
    echo "⚠️ Could not identify main target section. Using manual approach."
    
    # Create a temporary file for editing
    TMP_FILE=$(mktemp)
    cat "$PROJECT_PATH" > "$TMP_FILE"
    
    # Add the script run phase to known locations
    perl -i -pe '
        # Add script phase at the beginning of all buildPhases
        if (/buildPhases = \(/) {
            $_ .= "\n\t\t\t\t00000000000000000000001 /* Run Script */,";
        }
        
        # Add script phase at the end of all buildPhases
        if (/buildRules = \(/) {
            $_ = "\n\t\t\t\t00000000000000000000002 /* Run Script */,\n$_";
        }
        
        # Define the script phase
        if (/\/\* End PBXProject section \*\//) {
            $_ = "/* Begin PBXShellScriptBuildPhase section */\n" .
                 "\t\t00000000000000000000001 /* Run Script */ = {\n" .
                 "\t\t\tisa = PBXShellScriptBuildPhase;\n" .
                 "\t\t\tbuildActionMask = 2147483647;\n" .
                 "\t\t\tfiles = (\n\t\t\t);\n" .
                 "\t\t\tinputFileListPaths = (\n\t\t\t);\n" .
                 "\t\t\tinputPaths = (\n\t\t\t);\n" .
                 "\t\t\toutputFileListPaths = (\n\t\t\t);\n" .
                 "\t\t\toutputPaths = (\n\t\t\t);\n" .
                 "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n" .
                 "\t\t\tshellPath = /bin/sh;\n" .
                 "\t\t\tshellScript = \"${SRCROOT}/remove_infoplist_duplicates.sh\";\n" .
                 "\t\t};\n" .
                 "\t\t00000000000000000000002 /* Run Script */ = {\n" .
                 "\t\t\tisa = PBXShellScriptBuildPhase;\n" .
                 "\t\t\tbuildActionMask = 2147483647;\n" .
                 "\t\t\tfiles = (\n\t\t\t);\n" .
                 "\t\t\tinputFileListPaths = (\n\t\t\t);\n" .
                 "\t\t\tinputPaths = (\n\t\t\t);\n" .
                 "\t\t\toutputFileListPaths = (\n\t\t\t);\n" .
                 "\t\t\toutputPaths = (\n\t\t\t);\n" .
                 "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n" .
                 "\t\t\tshellPath = /bin/sh;\n" .
                 "\t\t\tshellScript = \"${SRCROOT}/remove_infoplist_duplicates.sh\";\n" .
                 "\t\t};\n" .
                 "/* End PBXShellScriptBuildPhase section */\n$_";
        }
    ' "$TMP_FILE"
    
    # Move the updated file back
    mv "$TMP_FILE" "$PROJECT_PATH"
    
    echo "✅ Added Run Script phases to remove duplicate Info.plist files"
else
    echo "⚠️ Automated script insertion not performed due to complexity. Please add manually."
    echo "Instructions to add Run Script phase manually:"
    echo "1. Open your project in Xcode"
    echo "2. Select your target"
    echo "3. Go to Build Phases"
    echo "4. Click '+' and select 'New Run Script Phase'"
    echo "5. Move it to be the FIRST build phase"
    echo "6. Set the script to: ${PWD}/remove_infoplist_duplicates.sh"
    echo "7. Add a second identical Run Script phase at the END of the build phases"
fi

echo ""
echo "⚠️ IMPORTANT: If the automated script insertion didn't work, add the Run Script phases manually as described above."
echo ""
echo "Now please:"
echo "1. Clean your build folder (Product > Clean Build Folder)"
echo "2. Delete the DerivedData folder:"
echo "   rm -rf ~/Library/Developer/Xcode/DerivedData/debot-*"
echo "3. Quit and restart Xcode completely"
echo "4. Build the project again"

exit 0 