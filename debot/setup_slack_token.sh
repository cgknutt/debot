#!/bin/bash

# This script helps set up the Slack token for the debot app

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Debot Slack Token Setup${NC}"
echo "============================"
echo

# Get Documents directory path
DOCUMENTS_DIR="$HOME/Documents"
CONFIG_FILE="$DOCUMENTS_DIR/SlackConfig.plist"

# Check if the token file already exists
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}A configuration file already exists at:${NC}"
    echo "$CONFIG_FILE"
    echo
    echo -e "${YELLOW}Current contents:${NC}"
    plutil -p "$CONFIG_FILE"
    echo
    
    read -p "Do you want to replace it? (y/n): " replace
    if [[ $replace != "y" ]]; then
        echo "Keeping existing configuration."
        exit 0
    fi
fi

# Ask for Slack Bot token
echo -e "${YELLOW}Please enter your Slack Bot token${NC}"
echo "It should start with 'xoxb-'"
echo -e "${YELLOW}You can get one from:${NC}"
echo "https://api.slack.com/apps > Your App > OAuth & Permissions"
echo
read -p "Slack Bot Token: " token

if [[ ! $token == xoxb-* ]]; then
    echo -e "${RED}Error: Token must start with 'xoxb-' (Bot token)${NC}"
    echo "Please verify you're using a Bot token, not a User token (xoxp-) or App token (xapp-)"
    exit 1
fi

# Create the plist file
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>SLACK_BOT_TOKEN</key>
    <string>$token</string>
    <key>INSTRUCTIONS</key>
    <string>This file contains your Slack Bot token. DO NOT commit it to git.</string>
</dict>
</plist>" > "$CONFIG_FILE"

# Check if the file was created successfully
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}Success!${NC} SlackConfig.plist has been created at:"
    echo "$CONFIG_FILE"
    echo
    echo "Your token has been stored securely. The app should now be able to connect to Slack."
    echo
    echo -e "${YELLOW}IMPORTANT:${NC} Make sure your Slack Bot has the following OAuth scopes:"
    echo "- channels:history - To view messages in channels"
    echo "- channels:read    - To list available channels"
    echo "- channels:join    - To join channels"
    echo "- chat:write       - To send messages"
    echo "- reactions:write  - To add reactions to messages"
    echo "- users:read       - To get user information"
    
    # Print the file permissions
    echo
    echo "File permissions:"
    ls -l "$CONFIG_FILE"
else
    echo -e "${RED}Error:${NC} Failed to create configuration file."
    echo "Please check if you have write permissions to $DOCUMENTS_DIR"
fi 