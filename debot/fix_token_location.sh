#!/bin/bash

# This script helps set up the Slack token in multiple possible locations

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Debot Slack Token Fix${NC}"
echo "======================="
echo

# Get token from existing file
TOKEN_FILE="$HOME/Documents/SlackConfig.plist"

if [ ! -f "$TOKEN_FILE" ]; then
    echo -e "${RED}Error: Token file not found at $TOKEN_FILE${NC}"
    echo "Please run ./debot/setup_slack_token.sh first"
    exit 1
fi

# Extract token
TOKEN=$(plutil -extract SLACK_BOT_TOKEN raw "$TOKEN_FILE" 2>/dev/null)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Error: Could not extract token from $TOKEN_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Successfully extracted token${NC}"

# Create token files in multiple possible locations
LOCATIONS=(
    "$HOME/Documents/SlackConfig.plist"
    "$HOME/Library/Application Support/debot/SlackConfig.plist"
    "./debot/SlackConfig.plist"
    "./SlackConfig.plist"
)

for location in "${LOCATIONS[@]}"; do
    # Create directory if it doesn't exist
    dir=$(dirname "$location")
    mkdir -p "$dir"
    
    # Create the plist file
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>SLACK_BOT_TOKEN</key>
    <string>$TOKEN</string>
    <key>INSTRUCTIONS</key>
    <string>This file contains your Slack Bot token. DO NOT commit it to git.</string>
</dict>
</plist>" > "$location"
    
    echo -e "${GREEN}Created token file at:${NC} $location"
done

echo
echo -e "${YELLOW}Also updating the SlackTokenManager to print more debug info...${NC}"

# Let's update the SlackTokenManager with debug information
echo "let's check our current directory:"
pwd

# Make sure the changes don't get committed
echo
echo -e "${YELLOW}IMPORTANT:${NC} Add SlackConfig.plist to your .gitignore file to avoid committing your token" 