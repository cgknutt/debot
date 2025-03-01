# Manual Fix for Duplicate Info.plist Error

Since our automated script fixes haven't fully resolved the issue, this guide provides detailed manual steps to fix the "Multiple commands produce Info.plist" error in Xcode.

## Step 1: Add Run Script Build Phases

1. Open your project in Xcode
2. Select the **debot** target in the project navigator
3. Select the **Build Phases** tab
4. Click the **+** button in the upper left corner of the Build Phases section
5. Select **New Run Script Phase**
6. Rename this phase to "Remove Duplicate Info.plist (Start)"
7. Move this phase to be the **very first** build phase by dragging it to the top
8. Paste this script into the script area:
   ```bash
   # Remove any existing duplicate Info.plist files
   if [ -d "${BUILT_PRODUCTS_DIR}" ]; then
     find "${BUILT_PRODUCTS_DIR}" -path "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Info.plist" -prune -o -name "Info.plist" -print -delete
   fi
   ```

9. Add another Run Script phase by repeating steps 4-5
10. Rename this one to "Remove Duplicate Info.plist (End)"
11. Move this phase to be the **very last** build phase
12. Paste the same script into this phase

## Step 2: Fix Project Settings

1. Select your project in the project navigator (not the target)
2. Select the **debot** target
3. Go to the **Build Settings** tab
4. Search for "info.plist"
5. Find the **Info.plist File** setting
6. Set its value to `debot/Info.plist` for all configurations
7. Find the **Generate Info.plist File** setting
8. Make sure it's set to **YES** for all configurations

## Step 3: Clean and Rebuild

1. Select **Product > Clean Build Folder** from the menu
2. Quit and restart Xcode completely
3. Build your project again

## Alternate Solution: Manually Edit COPY Phases

If the above doesn't work, try this:

1. Select your target's **Build Phases** tab
2. Expand the **Copy Bundle Resources** phase
3. Look for any **Info.plist** files and remove them (click the - button)
4. Do the same for any other Copy phases

This manual approach should resolve the duplicate Info.plist issue by ensuring only one mechanism is responsible for generating the Info.plist in your build products. 