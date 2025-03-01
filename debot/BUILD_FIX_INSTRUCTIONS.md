# Build Error Fix Instructions

## Overview of the Problem

You're encountering two common Xcode build errors:

1. Multiple commands produce `.../Info.plist`
2. Multiple commands produce `.../README.md`

These errors occur when the build system tries to copy the same file to the same destination more than once.

## Solution Options

I've provided several scripts to help fix this issue. Here are the different approaches you can try, in order of recommended priority:

### Option 1: Add Build Phase Scripts in Xcode (Recommended)

1. Open your project in Xcode
2. Select the "debot" target
3. Go to the "Build Phases" tab
4. Click the "+" button in the top-left of the Build Phases section
5. Select "New Run Script Phase"
6. Rename this phase to "Pre-Build Fix"
7. Move this phase to be the FIRST item in the list (above "Target Dependencies")
8. In the script area, add:
   ```bash
   "${SRCROOT}/aggressive_fix.sh"
   ```
9. Add another Run Script phase at the END of all phases
10. Rename it to "Post-Build Cleanup"
11. In the script area, add:
   ```bash
   "${SRCROOT}/post_build_cleanup.sh"
   ```
12. Clean your project (Product > Clean Build Folder)
13. Build again

### Option 2: Manually Remove Files from Build Phases

1. Open your project in Xcode
2. Select the "debot" target
3. Go to the "Build Phases" tab
4. Expand the "Copy Bundle Resources" section
5. Look for all README.md files and remove them (select and press Delete)
6. Look for any duplicate Info.plist files and keep only the main one
7. Clean your project (Product > Clean Build Folder)
8. Build again

### Option 3: Direct Project File Modification

If the above options don't work, you've already applied some direct fixes to the project file with these scripts:
- `fix_project.sh` - Removes README.md references from the project
- `direct_fix.sh` - Makes more extensive modifications to the project file

### Option 4: Temporary File Relocation

As a last resort, I've temporarily moved problematic README.md files to a backup location:
```
debot/temp_backup/
```

You can restore them after a successful build.

## Prevention for the Future

To prevent these issues from recurring:
- Don't include README.md files in your Copy Bundle Resources phase
- Make sure only one Info.plist is referenced in your build settings
- Consider adding .nodocopy files next to documentation files that shouldn't be copied to the app bundle

## Support

If these solutions don't resolve your issue, additional debugging may be needed to identify what's causing the duplicate file issues in your build process. 