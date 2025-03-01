# Project File Restore & Manual Fix Instructions

## Project Restoration

I've restored your project file from a backup to fix the corruption. The project should now open properly in Xcode again.

## Safe Manual Fix for Info.plist Issues

The automated scripts we attempted earlier likely caused the project file corruption. Here's a much safer manual approach:

### 1. Open the Project in Xcode

First make sure the project opens correctly after the restore.

### 2. Add a Simple Run Script Phase

1. Select your target (debot) in the project navigator
2. Select the **Build Phases** tab
3. Click the **+** button and select **New Run Script Phase**
4. Move it to be the **last** phase by dragging it
5. Rename it to "Remove Duplicate Info.plist"
6. Paste this script (much simpler than before):

```bash
# Remove duplicate Info.plist files from build directory
if [ -d "${BUILT_PRODUCTS_DIR}" ]; then
  # Keep the main Info.plist but remove any others
  find "${BUILT_PRODUCTS_DIR}" -path "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Info.plist" -prune -o -name "Info.plist" -delete
fi
```

### 3. Fix Info.plist Settings

1. Still in Xcode, select your project in the navigator
2. Select the **debot** target
3. Go to the **Build Settings** tab
4. Search for "info.plist"
5. Set **Info.plist File** (INFOPLIST_FILE) to `debot/Info.plist` for all configurations
6. Make sure **Generate Info.plist File** (GENERATE_INFOPLIST_FILE) is set to **YES**

### 4. Remove Any Info.plist from Copy Resources

1. Go back to the **Build Phases** tab
2. Expand the **Copy Bundle Resources** phase
3. Look for any **Info.plist** entries and remove them (click the - button)

### 5. Clean and Build

1. Clean your build folder: **Product > Clean Build Folder**
2. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/debot-*` 
3. Quit and restart Xcode
4. Build your project again

This manual approach is much safer than the automated scripts we tried earlier, as it avoids direct manipulation of the complex project file format. 