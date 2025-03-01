#!/bin/bash

# This script handles post-build cleanup and restoration
# Add this as a Run Script phase AFTER the Copy Bundle Resources phase

echo "🧹 Running post-build cleanup..."

# Directory for build process temporary files
DERIVED_DIR="${DERIVED_FILE_DIR}"

# Check if we need to restore README files
README_SCRIPT="${DERIVED_DIR}/restore_readme_files.sh"
if [ -f "$README_SCRIPT" ]; then
  echo "Restoring README.md files..."
  bash "$README_SCRIPT"
  rm "$README_SCRIPT"
fi

# Remove any duplicate files from the built product
if [ -d "$BUILT_PRODUCTS_DIR" ] && [ -d "$CONTENTS_FOLDER_PATH" ]; then
  PRODUCT_DIR="$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH"
  
  # Remove duplicate README.md files
  if [ -f "$PRODUCT_DIR/README.md" ]; then
    echo "Removing README.md from final product..."
    rm "$PRODUCT_DIR/README.md"
  fi
  
  # Ensure only one Info.plist exists
  INFO_PLIST_COUNT=$(find "$PRODUCT_DIR" -name "Info.plist" | wc -l | xargs)
  if [ "$INFO_PLIST_COUNT" -gt 1 ]; then
    echo "⚠️ Warning: Multiple Info.plist files in built product. Keeping only the main one."
    # Keep only the main Info.plist
    find "$PRODUCT_DIR" -path "$PRODUCT_DIR/Info.plist" -prune -o -name "Info.plist" -exec rm {} \;
  fi
fi

echo "✅ Post-build cleanup complete"
exit 0 