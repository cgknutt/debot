# Debot Asset Requirements

This document outlines the image assets required for the premium Debot flight tracker experience.

## 3D Globe Visualization Assets

The following images are required for the 3D globe visualization:

### Earth Textures

- `earth_satellite.jpg`: High-resolution satellite imagery of Earth (4096x2048px recommended)
- `earth_map.jpg`: Stylized map representation of Earth (4096x2048px recommended)
- `clouds_layer.png`: Semi-transparent cloud layer (4096x2048px with alpha channel)
- `stars_background.jpg`: Starfield for the background (4096x2048px)

### Aircraft Models

- `aircraft_commercial.png`: Commercial aircraft icon (256x256px with alpha channel)
- `aircraft_private.png`: Private aircraft icon (256x256px with alpha channel)

### Weather Icons

- `weather_clear.png`: Clear weather icon (128x128px with alpha channel)
- `weather_clouds.png`: Cloudy weather icon (128x128px with alpha channel)
- `weather_rain.png`: Rain weather icon (128x128px with alpha channel)
- `weather_snow.png`: Snow weather icon (128x128px with alpha channel)
- `weather_storm.png`: Storm weather icon (128x128px with alpha channel)

### UI Elements

- `loading_animation.json`: Lottie animation file for loading states
- `refresh_animation.json`: Lottie animation file for refresh action
- `notification_animation.json`: Lottie animation file for notifications

## Premium Theme Assets

- `luxury_background_dark.jpg`: Texture for dark luxury theme (1080x1920px)
- `luxury_background_light.jpg`: Texture for light luxury theme (1080x1920px)
- `card_texture_dark.jpg`: Card background texture for dark theme (512x512px)
- `card_texture_light.jpg`: Card background texture for light theme (512x512px)

## Airline Logos

Add airline logos to the following directory structure:
- `airlines/[airline_code].png`: Logo for each airline (256x256px with alpha channel)

## Airport Icons

- `airport_international.png`: International airport icon (128x128px)
- `airport_domestic.png`: Domestic airport icon (128x128px)
- `airport_private.png`: Private airport icon (128x128px)

## Implementation Notes

1. For development purposes, you can use placeholder images until the final assets are created.
2. All textures should use power-of-two dimensions for optimal GPU performance.
3. Use PNG format for images requiring transparency, JPG for opaque images.
4. Consider adding @2x and @3x versions for iOS devices with high-resolution displays.

## Asset Creation Guidelines

When creating or sourcing these assets:
- Ensure they are properly licensed for commercial use
- Optimize file sizes for mobile performance
- Maintain consistent visual style across all assets
- Use vector assets (PDF or SVG) where possible for UI elements

For the Earth textures, NASA's Blue Marble collection provides excellent source material that can be adapted:
https://visibleearth.nasa.gov/collection/1484/blue-marble 