# Debot

A modern iOS app built with Swift and SwiftUI.

## Requirements

- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later

## Installation

1. Clone the repository
2. Open `debot.xcodeproj` in Xcode
3. Build and run the project

## Slack Integration

Debot includes a Slack integration feature that allows you to connect to Slack channels and send/receive messages. To set up the Slack integration:

1. You need a Slack Bot token (starts with `xoxb-`)
2. Run the setup script: `./debot/setup_slack_token.sh`
3. Follow the prompts to enter your Slack Bot token
4. The token will be stored in your Documents directory (~/Documents/SlackConfig.plist)

### Slack Bot Setup

To create a Slack Bot and get a token:

1. Go to [https://api.slack.com/apps](https://api.slack.com/apps)
2. Click "Create New App" > "From scratch"
3. Name your app and select your workspace
4. Go to "OAuth & Permissions" and add the following scopes:
   - `channels:history` - To view messages in channels
   - `channels:read` - To list available channels
   - `channels:join` - To join channels
   - `chat:write` - To send messages
   - `reactions:write` - To add reactions to messages
   - `users:read` - To get user information
5. Install the app to your workspace
6. Copy the "Bot User OAuth Token" (starts with `xoxb-`)

If you're having connection issues, make sure:
- Your bot has been added to the channels you want to access
- Your bot has all the required OAuth scopes
- Your SlackConfig.plist file is correctly set up with a valid token

## Features

- Modern SwiftUI interface
- Clean architecture
- Slack integration with channel and message support
- [More features to be added]

## Project Structure

```
debot/
├── App/                 # App entry point and configuration
├── Features/           # Feature-specific views and logic
├── Core/              # Core functionality and shared components
│   ├── Models/       # Data models
│   ├── Services/     # Business logic and services
│   └── Utils/        # Utility functions and extensions
├── UI/               # Shared UI components
│   ├── Components/   # Reusable UI components
│   ├── Styles/       # SwiftUI styles and modifiers
│   └── Resources/    # Colors, images, and other resources
└── Preview Content/  # Preview assets for SwiftUI
```

## License

This project is licensed under the MIT License - see the LICENSE file for details. 