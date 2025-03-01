#!/bin/bash

# This script will fix Run Script build phases in the Xcode project
# by setting outputFileListPaths and alwaysOutOfDate to fix the warning

PROJECT_FILE="debot/debot.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Could not find project file at $PROJECT_FILE"
    exit 1
fi

# Create a backup of the project file
BACKUP_FILE="${PROJECT_FILE}.backup.$(date +%Y%m%d%H%M%S)"
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo "Created backup at $BACKUP_FILE"

# Find all Run Script build phases that lack outputFileListPaths
# and add the needed properties to eliminate the warning
TEMP_FILE=$(mktemp)

cat "$PROJECT_FILE" | awk '
BEGIN { 
    in_script_phase = 0;
    has_output_paths = 0;
    has_output_file_list_paths = 0;
    has_always_out_of_date = 0;
    buffer = "";
}

{
    # Check if this is a script phase section
    if ($0 ~ /shellScript = ".*";/ || $0 ~ /isa = PBXShellScriptBuildPhase;/) {
        in_script_phase = 1;
    }
    
    # Check if it already has outputPaths
    if ($0 ~ /outputPaths = \(/) {
        has_output_paths = 1;
    }
    
    # Check if it already has outputFileListPaths
    if ($0 ~ /outputFileListPaths = \(/) {
        has_output_file_list_paths = 1;
    }
    
    # Check if it already has alwaysOutOfDate
    if ($0 ~ /alwaysOutOfDate = [01];/) {
        has_always_out_of_date = 1;
    }
    
    # Buffer the current line
    buffer = buffer $0 "\n";
    
    # If we reach the end of a build phase section
    if (in_script_phase && $0 ~ /};/) {
        # Check if we need to add the missing properties
        if (!has_output_file_list_paths || !has_always_out_of_date) {
            # Remove the closing bracket
            sub(/};/, "", buffer);
            
            # Add outputFileListPaths if missing
            if (!has_output_file_list_paths) {
                buffer = buffer "\t\t\toutputFileListPaths = (\n\t\t\t);\n";
            }
            
            # Add alwaysOutOfDate if missing
            if (!has_always_out_of_date) {
                buffer = buffer "\t\t\talwaysOutOfDate = 0;\n";
            }
            
            # Add back the closing bracket
            buffer = buffer "\t\t};\n";
        }
        
        # Print the modified buffer
        printf "%s", buffer;
        
        # Reset for next section
        in_script_phase = 0;
        has_output_paths = 0;
        has_output_file_list_paths = 0;
        has_always_out_of_date = 0;
        buffer = "";
    }
}

# If we reach EOF and still have content in buffer, print it
END {
    if (buffer != "") {
        printf "%s", buffer;
    }
}
' > "$TEMP_FILE"

# Replace the original file with our modified version
mv "$TEMP_FILE" "$PROJECT_FILE"

echo "Updated project file: Added outputFileListPaths and alwaysOutOfDate = 0 to Run Script build phases"
echo "The build warning should now be fixed!" 