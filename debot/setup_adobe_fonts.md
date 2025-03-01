# Setting Up Cooper Black with Adobe Fonts

Since you're using Adobe Fonts, follow these steps to ensure Cooper Black is available in your app:

## Step 1: Activate Cooper Black in Adobe Fonts

1. Sign in to your [Adobe Creative Cloud](https://creativecloud.adobe.com/) account
2. Go to Adobe Fonts (formerly Typekit) in Creative Cloud
3. Search for "Cooper Black"
4. Click "Activate" to make it available on your system
5. Ensure Creative Cloud is running on your development machine

## Step 2: Find the Exact Font Name

You can find the exact PostScript name for Cooper Black using the FontDebugView:

1. Long-press anywhere in your app for 2 seconds to open the Font Debug view
2. OR Run the standalone font debug view:
   ```
   swift debot/show_font_debug.swift
   ```
3. Use the search field to find "cooper"
4. Look for fonts with "Cooper" in their name
5. Take note of the exact font name (e.g., "CooperBlackStd-Regular")

## Step 3: Update Your Font Extension

1. Open `debot/debot/UI/Styles/FontExtensions.swift`
2. Update the code to use the exact font name:

```swift
static func cooperBlack(size: CGFloat) -> Font {
    // Use the exact font name you found in the debug view
    let adobeFontName = "CooperBlackStd-Regular" // Replace with your font name
    
    // Try to use the Adobe Fonts version
    if let _ = UIFont(name: adobeFontName, size: size) {
        return Font.custom(adobeFontName, size: size)
    }
    
    // Fall back to system font if Adobe font is not available
    return Font.system(size: size, weight: .black, design: .rounded)
}
```

## Step 4: Clean and Rebuild

1. In Xcode, select Product > Clean Build Folder
2. Rebuild and run the app

## Troubleshooting

If Cooper Black still doesn't appear:

1. Make sure Creative Cloud is running on your development machine
2. Try restarting your Mac to refresh the font cache
3. Verify you've activated Cooper Black in Adobe Fonts
4. Check if your Adobe CC subscription includes Adobe Fonts access
5. Use the FontDebugView to see what fonts are actually available

## Alternative: Bundle the Font

If you continue to have issues with Adobe Fonts, consider:

1. Purchasing a licensed copy of Cooper Black from a type foundry
2. Adding the font file directly to your Xcode project
3. Updating Info.plist with the UIAppFonts key 