#!/bin/bash

# Comprehensive script to fix the Info.plist code signing issue
echo "🔧 Running comprehensive fix for Info.plist code signing issue..."

# 1. First, ensure Info.plist has the right contents
INFO_PLIST_PATH="debot/Info.plist"
echo "🔍 Checking Info.plist at $INFO_PLIST_PATH..."

if [ ! -f "$INFO_PLIST_PATH" ]; then
    echo "⚠️ Info.plist not found. Creating it..."
    mkdir -p $(dirname "$INFO_PLIST_PATH")
    touch "$INFO_PLIST_PATH"
fi

echo "✅ Ensuring Info.plist has all required keys..."
cat > "$INFO_PLIST_PATH" << 'EOL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>api.aviationstack.com</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
                <key>NSIncludesSubdomains</key>
                <true/>
            </dict>
        </dict>
    </dict>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
        <key>UISceneConfigurations</key>
        <dict/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
EOL

# 2. Fix the project file settings
PROJECT_PATH="debot.xcodeproj/project.pbxproj"
echo "🔧 Fixing project settings in $PROJECT_PATH..."

if [ ! -f "$PROJECT_PATH" ]; then
    echo "❌ Error: Could not find project file at $PROJECT_PATH"
    exit 1
fi

# Back up the project file
BACKUP_PATH="${PROJECT_PATH}.final.bak"
cp "$PROJECT_PATH" "$BACKUP_PATH"
echo "📋 Created backup at $BACKUP_PATH"

echo "🔍 Applying targeted fixes to project settings..."

# Create a temporary file with all the edits
TMP_FILE=$(mktemp)
cat "$PROJECT_PATH" > "$TMP_FILE"

# Set INFOPLIST_FILE to point to the actual Info.plist
perl -pi -e 's/INFOPLIST_FILE = .*/INFOPLIST_FILE = "debot\/Info.plist";/g' "$TMP_FILE"

# Fix GENERATE_INFOPLIST_FILE to be YES (not a path)
perl -pi -e 's/GENERATE_INFOPLIST_FILE = ".*";/GENERATE_INFOPLIST_FILE = YES;/g' "$TMP_FILE"

# Find all build configuration sections
perl -pi -e 'if (/buildSettings = \{/ && !/GENERATE_INFOPLIST_FILE/) { $_ .= "\n\t\t\t\tGENERATE_INFOPLIST_FILE = YES;\n"; }' "$TMP_FILE"

# Ensure all INFOPLIST_FILE settings point to the right file
perl -pi -e 'if (/buildSettings = \{/ && !/INFOPLIST_FILE = /) { $_ .= "\n\t\t\t\tINFOPLIST_FILE = \"debot\/Info.plist\";\n"; }' "$TMP_FILE"

# Move the updated file back
mv "$TMP_FILE" "$PROJECT_PATH"

# 3. Touch Info.plist to update modification time
touch "$INFO_PLIST_PATH"

echo "✅ Comprehensive fix applied!"
echo ""
echo "Now please:"
echo "1. Clean your build folder (Product > Clean Build Folder)"
echo "2. Quit and restart Xcode completely"
echo "3. Build the project again"

exit 0 