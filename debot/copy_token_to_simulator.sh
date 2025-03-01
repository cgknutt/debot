#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Copying Slack Token to iOS Simulator${NC}"
echo "======================================"
echo

# Source token file
SOURCE_TOKEN_FILE="$HOME/Documents/SlackConfig.plist"

if [ ! -f "$SOURCE_TOKEN_FILE" ]; then
    echo -e "${RED}Error: Source token file not found at $SOURCE_TOKEN_FILE${NC}"
    exit 1
fi

# Extract the token to verify it's valid
TOKEN=$(plutil -extract SLACK_BOT_TOKEN raw "$SOURCE_TOKEN_FILE" 2>/dev/null)

if [ -z "$TOKEN" ] || [ "$TOKEN" == "REPLACE_WITH_YOUR_SLACK_BOT_TOKEN" ]; then
    echo -e "${RED}Error: Invalid or placeholder token in $SOURCE_TOKEN_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Successfully verified source token${NC}"

# Find the simulator's SlackConfig.plist file
SIM_FILES=$(find ~/Library/Developer/CoreSimulator/Devices -name "SlackConfig.plist" 2>/dev/null | grep -v "/data/Containers/Data/PluginKitPlugin/")

if [ -z "$SIM_FILES" ]; then
    echo -e "${YELLOW}No SlackConfig.plist found in simulators. Run the app first to create it.${NC}"
    exit 1
fi

# Copy to each found simulator file
for SIM_FILE in $SIM_FILES; do
    echo -e "${YELLOW}Copying token to:${NC} $SIM_FILE"
    
    # Create the plist file with the real token
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>SLACK_BOT_TOKEN</key>
    <string>$TOKEN</string>
    <key>INSTRUCTIONS</key>
    <string>This file contains your Slack Bot token. DO NOT commit it to git.</string>
</dict>
</plist>" > "$SIM_FILE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully copied token to simulator${NC}"
        
        # Verify the copy
        SIM_TOKEN=$(plutil -extract SLACK_BOT_TOKEN raw "$SIM_FILE" 2>/dev/null)
        if [ "$SIM_TOKEN" == "$TOKEN" ]; then
            echo -e "${GREEN}Verified token was correctly copied${NC}"
        else
            echo -e "${RED}Token verification failed for $SIM_FILE${NC}"
        fi
    else
        echo -e "${RED}Failed to copy token to $SIM_FILE${NC}"
    fi
done

echo
echo -e "${GREEN}Done!${NC} Now restart your app in the simulator to use the real token."
echo -e "${YELLOW}Note:${NC} If you run the app in a different simulator, you may need to run this script again." 