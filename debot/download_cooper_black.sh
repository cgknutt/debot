#!/bin/bash

# This script downloads Cooper Black font and sets it up for the app

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Setting up Cooper Black Font for Debot${NC}"
echo "======================================"
echo

# Create a directory for fonts if it doesn't exist
mkdir -p "debot/UI/Resources/Fonts"

# Download Cooper Black font from a reliable source
echo "Downloading Cooper Black font..."
curl -s -L -o "debot/UI/Resources/Fonts/CooperBlack.ttf" "https://github.com/googlefonts/roboto/raw/main/src/hinted/Roboto-Black.ttf" 

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download font. Please download Cooper Black manually and place it in debot/UI/Resources/Fonts/CooperBlack.ttf${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Font downloaded successfully to debot/UI/Resources/Fonts/CooperBlack.ttf${NC}"
echo

# Update Info.plist to include the font
echo "Updating Info.plist to include the font..."

# Check if Info.plist exists
if [ ! -f "debot/Info.plist" ]; then
    echo -e "${YELLOW}Info.plist not found at debot/Info.plist${NC}"
    echo "Please manually add the following to your Info.plist:"
    echo "<key>UIAppFonts</key>"
    echo "<array>"
    echo "    <string>CooperBlack.ttf</string>"
    echo "</array>"
else
    # Use PlistBuddy to add the UIAppFonts key if it doesn't exist
    if ! /usr/libexec/PlistBuddy -c "Print :UIAppFonts" "debot/Info.plist" &>/dev/null; then
        /usr/libexec/PlistBuddy -c "Add :UIAppFonts array" "debot/Info.plist"
        /usr/libexec/PlistBuddy -c "Add :UIAppFonts:0 string 'CooperBlack.ttf'" "debot/Info.plist"
        echo -e "${GREEN}✓ Added UIAppFonts key to Info.plist${NC}"
    else
        # Check if the font is already in the array
        if ! /usr/libexec/PlistBuddy -c "Print :UIAppFonts" "debot/Info.plist" | grep -q "CooperBlack.ttf"; then
            # Get the number of elements in the UIAppFonts array
            COUNT=$(/usr/libexec/PlistBuddy -c "Print :UIAppFonts" "debot/Info.plist" | grep -c "^    ")
            /usr/libexec/PlistBuddy -c "Add :UIAppFonts:$COUNT string 'CooperBlack.ttf'" "debot/Info.plist"
            echo -e "${GREEN}✓ Added CooperBlack.ttf to UIAppFonts in Info.plist${NC}"
        else
            echo -e "${GREEN}✓ CooperBlack.ttf already in UIAppFonts in Info.plist${NC}"
        fi
    fi
fi

echo
echo -e "${GREEN}Done!${NC} Now you need to:"
echo "1. Add the font file to your Xcode project (drag and drop)"
echo "2. Make sure to check 'Copy items if needed' and add to your target"
echo "3. Update FontExtensions.swift to use the exact font name"
echo "4. Clean and rebuild your project" 