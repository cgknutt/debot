# Sandbox-Safe Run Script for Xcode

The error you're seeing is a sandbox permission issue. Our cleanup script is triggering permission errors when trying to use the "find" command.

## Replace Your Run Script with This Version

In Xcode, modify your existing Run Script phase (or create a new one) with this sandbox-safe version:

```bash
# Sandbox-safe script to handle Info.plist duplication
# This avoids using commands that may trigger sandbox restrictions

# Define function to log messages
log_message() {
  echo "📝 $1"
}

log_message "Running Info.plist cleanup..."

# Only proceed if we have a built products directory
if [ -d "${BUILT_PRODUCTS_DIR}" ]; then
  log_message "Checking for duplicate Info.plist files..."
  
  # Main Info.plist that should be kept
  MAIN_PLIST="${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Info.plist"
  
  # Check if we're building an app bundle
  if [ -d "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}" ]; then
    # Use a direct approach instead of find to avoid sandbox issues
    if [ -f "$MAIN_PLIST" ]; then
      log_message "Found main Info.plist at expected location"
      
      # Check for specific known duplicate locations
      DUPLICATE_PATHS=(
        "${BUILT_PRODUCTS_DIR}/Info.plist"
        "${BUILT_PRODUCTS_DIR}/debot/Info.plist"
      )
      
      for DUPLICATE in "${DUPLICATE_PATHS[@]}"; do
        if [ -f "$DUPLICATE" ] && [ "$DUPLICATE" != "$MAIN_PLIST" ]; then
          log_message "Removing duplicate at $DUPLICATE"
          rm "$DUPLICATE"
        fi
      done
    fi
  fi
fi

log_message "Info.plist cleanup complete"
```

## Other Fixes to Try

If the sandbox issue persists, try these options:

1. **Manually Remove Info.plist from Copy Resources**
   - Make sure you've checked Build Phases > Copy Bundle Resources and removed any Info.plist files

2. **Disable the Run Script Temporarily**
   - Uncheck the "Run script" checkbox in the Run Script phase to disable it

3. **Clean Build Folder and Derived Data**
   ```
   rm -rf ~/Library/Developer/Xcode/DerivedData/debot-*
   ```

4. **Check Signing & Capabilities**
   - Make sure your app's signing configuration is correct
   - Verify entitlements if you're using any special capabilities

5. **Check for Duplicate Targets**
   - Ensure you don't have duplicate targets with the same output names 