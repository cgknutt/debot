#!/bin/bash

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null; then
    echo "ImageMagick is not installed. Installing via Homebrew..."
    brew install imagemagick
fi

# Create the directory structure
mkdir -p debot/debot/Assets.xcassets/AppIcon.appiconset

# Array of sizes needed for iOS app icons
sizes=(
    "1024x1024"
    "180x180"
    "167x167"
    "152x152"
    "120x120"
    "87x87"
    "80x80"
    "76x76"
    "60x60"
    "58x58"
    "40x40"
    "29x29"
    "20x20"
)

# Export icons in different sizes
for size in "${sizes[@]}"; do
    magick "debot_icon.png" -strip -quality 100 -resize "${size}^" -gravity center -extent "${size}" "debot/debot/Assets.xcassets/AppIcon.appiconset/icon_${size}.png"
done

# Create Contents.json
cat > debot/debot/Assets.xcassets/AppIcon.appiconset/Contents.json << 'EOL'
{
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "icon_40x40.png",
      "scale" : "2x"
    },
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "icon_60x60.png",
      "scale" : "3x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "icon_58x58.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "icon_87x87.png",
      "scale" : "3x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "icon_80x80.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "icon_120x120.png",
      "scale" : "3x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "icon_120x120.png",
      "scale" : "2x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "icon_180x180.png",
      "scale" : "3x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "icon_20x20.png",
      "scale" : "1x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "icon_40x40.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "icon_29x29.png",
      "scale" : "1x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "icon_58x58.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "icon_40x40.png",
      "scale" : "1x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "icon_80x80.png",
      "scale" : "2x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "icon_76x76.png",
      "scale" : "1x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "icon_152x152.png",
      "scale" : "2x"
    },
    {
      "size" : "83.5x83.5",
      "idiom" : "ipad",
      "filename" : "icon_167x167.png",
      "scale" : "2x"
    },
    {
      "size" : "1024x1024",
      "idiom" : "ios-marketing",
      "filename" : "icon_1024x1024.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOL

echo "Icon export complete! The icons have been added to your Xcode project's asset catalog." 