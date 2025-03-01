# Bundling Cooper Black Font with the App

Since Cooper Black isn't installed on your system, you have two options:

## Option 1: Install Cooper Black on your system

1. Download Cooper Black font from a reputable source
2. Install the font by double-clicking the file and clicking "Install Font"

## Option 2: Bundle Cooper Black with the app

This is the recommended approach to ensure consistent typography across all devices:

### Step 1: Download Cooper Black Font

1. Ensure you have proper license to bundle the font
2. Download the Cooper Black TTF or OTF file

### Step 2: Add to Xcode Project

1. In Xcode, right-click on your project navigator
2. Select "Add Files to [YourApp]..."
3. Navigate to and select the Cooper Black font file
4. Ensure "Copy items if needed" is checked
5. Add to your app's target

### Step 3: Update Info.plist

1. Open Info.plist in your project
2. Add a new key: "Fonts provided by application" (UIAppFonts)
3. Add the filename of your font file, e.g., "CooperBlack.ttf"

```xml
<key>UIAppFonts</key>
<array>
    <string>CooperBlack.ttf</string>
</array>
```

### Step 4: Verify Font Name

1. In Xcode, select your font file
2. Open the Font Book preview
3. Note the exact PostScript name of the font (e.g., "CooperBlack")
4. Update your FontExtensions.swift file with the exact name:

```swift
static func cooperBlack(size: CGFloat) -> Font {
    return Font.custom("CooperBlack", size: size) // Use exact PostScript name here
}
```

### Step 5: Test on a Device

After bundling the font, test on a physical device to ensure the font loads properly.

## Legal Note

Be sure you have the appropriate license to bundle Cooper Black with your application. Some fonts require specific licenses for app distribution. 