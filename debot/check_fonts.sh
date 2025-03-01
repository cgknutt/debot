#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Checking for Cooper Black Font in System${NC}"
echo "======================================="
echo

# Check if Creative Cloud is running
if pgrep "Creative Cloud" > /dev/null; then
    echo -e "${GREEN}✅ Adobe Creative Cloud is running${NC}"
else
    echo -e "${RED}❌ Adobe Creative Cloud is NOT running${NC}"
    echo "You should start Creative Cloud for Adobe Fonts to be available"
fi

echo

# Check system fonts for Cooper Black
echo "Checking system font directory for Cooper fonts..."
FONT_DIRS=(
    "/Library/Fonts"
    "/System/Library/Fonts"
    "$HOME/Library/Fonts"
    "$HOME/Library/Application Support/Adobe/CoreSync/plugins/livetype"
)

FOUND_COOPER=false

for dir in "${FONT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        RESULTS=$(find "$dir" -type f -name "*Cooper*" 2>/dev/null)
        if [ -n "$RESULTS" ]; then
            echo -e "${GREEN}Found Cooper fonts in $dir:${NC}"
            echo "$RESULTS" | while read font; do
                echo "  - $(basename "$font")"
            done
            FOUND_COOPER=true
        fi
    fi
done

# Check with system_profiler
echo
echo "Checking Font Book database..."
if system_profiler SPFontsDataType 2>/dev/null | grep -i "Cooper" > /dev/null; then
    echo -e "${GREEN}✅ Cooper fonts found in Font Book!${NC}"
    echo "Cooper fonts in system:"
    system_profiler SPFontsDataType 2>/dev/null | grep -i -A 1 -B 1 "Cooper"
    FOUND_COOPER=true
else
    echo -e "${RED}❌ No Cooper fonts found in Font Book${NC}"
fi

if [ "$FOUND_COOPER" = false ]; then
    echo
    echo -e "${RED}No Cooper fonts found on your system.${NC}"
    echo
    echo "Recommendations:"
    echo "1. Ensure Adobe Creative Cloud is running"
    echo "2. Verify Cooper Std Black is activated in Adobe Fonts"
    echo "3. Try restarting your Mac to refresh the font cache"
    echo "4. Check if your Adobe CC subscription includes Adobe Fonts"
else
    echo
    echo -e "${GREEN}Cooper fonts found on your system!${NC}"
    echo
    echo "Next steps:"
    echo "1. Update FontExtensions.swift with the exact font name"
    echo "2. Clean and rebuild your Xcode project"
    echo "3. If font still doesn't load, restart your Mac"
fi

echo
echo "Adobe Fonts PostScript naming format is typically:"
echo "  - Display name in Adobe app: 'Cooper Std Black'"
echo "  - Actual PostScript name: 'CooperStd-Black'"
echo "Try both in your code!" 