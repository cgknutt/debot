#!/bin/bash

# This script checks for Cooper Black font availability on the system

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Checking Cooper Black Font Availability${NC}"
echo "========================================"
echo

# Check macOS for Cooper Black
echo "Checking system fonts..."

# First try to find font using macOS's system_profiler
if system_profiler SPFontsDataType 2>/dev/null | grep -q "Cooper Black"; then
    echo -e "${GREEN}✓ Cooper Black font found in system fonts!${NC}"
    FOUND=true
else
    # Alternative check using Font Book app's database
    if [ -d "$HOME/Library/Fonts" ] && ls "$HOME/Library/Fonts" 2>/dev/null | grep -i "cooper" | grep -i "black"; then
        echo -e "${GREEN}✓ Cooper Black font found in user fonts!${NC}"
        FOUND=true
    elif [ -d "/Library/Fonts" ] && ls "/Library/Fonts" 2>/dev/null | grep -i "cooper" | grep -i "black"; then
        echo -e "${GREEN}✓ Cooper Black font found in system fonts directory!${NC}"
        FOUND=true
    elif [ -d "/System/Library/Fonts" ] && ls "/System/Library/Fonts" 2>/dev/null | grep -i "cooper" | grep -i "black"; then
        echo -e "${GREEN}✓ Cooper Black font found in system fonts directory!${NC}"
        FOUND=true
    else
        FOUND=false
        echo -e "${RED}✗ Cooper Black font not found in system fonts.${NC}"
    fi
fi

if [ "$FOUND" == "false" ]; then
    echo -e "\n${YELLOW}Font not found. Here are your options:${NC}"
    echo "1. Install Cooper Black font manually:"
    echo "   - Download Cooper Black font from a reputable source"
    echo "   - Open the font file and click 'Install Font'"
    echo
    echo "2. On macOS, Cooper Black should be pre-installed. If not, you can get it by installing:"
    echo "   - Microsoft Office suite (includes Cooper Black)"
    echo "   - Adobe Creative Cloud apps"
    echo
    echo "3. Alternative: Update the app to bundle Cooper Black if legally permitted"
    echo "   - Add the font file to your Xcode project"
    echo "   - Include it in the Info.plist under UIAppFonts"
    echo "   - Ensure you have the proper license for bundling"
    echo
    echo -e "${YELLOW}Note:${NC} Without Cooper Black installed, the app will fallback to system fonts."
else
    echo -e "\n${GREEN}Cooper Black is installed and ready to use!${NC}"
    echo "The app will use Cooper Black for all text elements."
fi 