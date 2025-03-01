#!/bin/bash

# AGGRESSIVE FIX FOR DUPLICATE FILES IN BUILD PRODUCTS
# Add this as the FIRST Run Script build phase in your Xcode project
# This script should be added BEFORE any other build phases

echo "🛡️ RUNNING AGGRESSIVE BUILD FIX"

# Set up trap to capture and show errors
trap 'echo "❌ ERROR at line $LINENO: $BASH_COMMAND"; exit 1' ERR

# Function to log with timestamp
log() {
  echo "$(date +"%H:%M:%S"): $1"
}

log "Starting aggressive build fix..."

# Ensure build output directories exist
if [ -z "$BUILT_PRODUCTS_DIR" ]; then
  log "⚠️ BUILT_PRODUCTS_DIR not set, running in test mode"
  BUILT_PRODUCTS_DIR="$TEMP_DIR/Products"
  mkdir -p "$BUILT_PRODUCTS_DIR"
fi

# Find and list all README.md files in source
log "Identifying README.md files in source..."
README_FILES=$(find "$SRCROOT" -name "README.md" -not -path "*/\.*" | xargs)
log "Found README files: $README_FILES"

# Find and list all Info.plist files in source
log "Identifying Info.plist files in source..."
INFO_PLIST_FILES=$(find "$SRCROOT" -name "Info.plist" -not -path "*/\.*" | xargs)
log "Found Info.plist files: $INFO_PLIST_FILES"

# Make sure we have the correct main Info.plist
MAIN_INFO_PLIST="$SRCROOT/debot/Info.plist"
log "Main Info.plist should be: $MAIN_INFO_PLIST"
if [ ! -f "$MAIN_INFO_PLIST" ]; then
  log "⚠️ Warning: Main Info.plist not found at expected path"
fi

# AGGRESSIVE FIX 1: Create .nodocopy files to prevent copying
log "Creating .nodocopy markers for README.md files..."
for file in $README_FILES; do
  touch "${file}.nodocopy"
  log "Created marker: ${file}.nodocopy"
done

# AGGRESSIVE FIX 2: Pre-clean build products directory
if [ -d "$BUILT_PRODUCTS_DIR" ]; then
  log "Pre-cleaning any existing README.md and Info.plist in build products..."
  find "$BUILT_PRODUCTS_DIR" -name "README.md" -delete
  find "$BUILT_PRODUCTS_DIR" -path "*/debot.app/Info.plist" -prune -o -name "Info.plist" -delete
fi

# AGGRESSIVE FIX 3: Modify environment variables to force correct Info.plist
export INFOPLIST_FILE="debot/Info.plist"
log "Forcing INFOPLIST_FILE to: $INFOPLIST_FILE"

log "Aggressive build fix completed successfully!"
echo "----------------------------------------------------------------"
echo "If build succeeds, you can restore the README.md files with:"
echo "find \"$SRCROOT\" -name \"*.nodocopy\" -delete"
echo "----------------------------------------------------------------"

exit 0 