#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Updating Info.plist to include Cooper Black font${NC}"
echo "=============================================="

# Find Info.plist in the project
INFO_PLIST_PATHS=(
  "debot/Info.plist"
  "debot/debot/Info.plist"
)

INFO_PLIST=""
for path in "${INFO_PLIST_PATHS[@]}"; do
  if [ -f "$path" ]; then
    INFO_PLIST="$path"
    break
  fi
done

if [ -z "$INFO_PLIST" ]; then
  echo -e "${RED}Error: Info.plist not found in expected locations${NC}"
  echo "Please manually add the following to your Info.plist:"
  echo "<key>UIAppFonts</key>"
  echo "<array>"
  echo "    <string>CooperBlack.ttf</string>"
  echo "</array>"
  exit 1
fi

echo "Found Info.plist at: $INFO_PLIST"

# Use PlistBuddy to add the UIAppFonts key if it doesn't exist
if ! /usr/libexec/PlistBuddy -c "Print :UIAppFonts" "$INFO_PLIST" &>/dev/null; then
  /usr/libexec/PlistBuddy -c "Add :UIAppFonts array" "$INFO_PLIST"
  /usr/libexec/PlistBuddy -c "Add :UIAppFonts:0 string 'CooperBlack.ttf'" "$INFO_PLIST"
  echo -e "${GREEN}✅ Added UIAppFonts key to Info.plist${NC}"
else
  # Check if the font is already in the array
  if ! /usr/libexec/PlistBuddy -c "Print :UIAppFonts" "$INFO_PLIST" | grep -q "CooperBlack.ttf"; then
    # Get the number of elements in the UIAppFonts array
    COUNT=$(/usr/libexec/PlistBuddy -c "Print :UIAppFonts" "$INFO_PLIST" | grep -c "^    ")
    /usr/libexec/PlistBuddy -c "Add :UIAppFonts:$COUNT string 'CooperBlack.ttf'" "$INFO_PLIST"
    echo -e "${GREEN}✅ Added CooperBlack.ttf to UIAppFonts in Info.plist${NC}"
  else
    echo -e "${GREEN}✅ CooperBlack.ttf already in UIAppFonts in Info.plist${NC}"
  fi
fi

echo -e "\n${GREEN}Done!${NC} Now you need to:"
echo "1. Make sure the font file is added to your Xcode project (drag and drop it in Xcode)"
echo "2. Check 'Copy items if needed' and add to your target when prompted"
echo "3. Update FontExtensions.swift to use the exact PostScript name of your font"
echo "4. Clean and rebuild your project" 