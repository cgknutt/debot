# Debot - World's Best Flight Tracker

![Debot Logo](./Assets.xcassets/AppIcon.appiconset/icon-1024.png)

## Overview

Debot is a revolutionary flight tracking application that sets a new global standard for aviation enthusiasts, frequent travelers, and aviation professionals. With its stunning 3D visualizations, real-time data, and intelligent predictive features, Debot offers an unmatched flight tracking experience on iOS.

## Key Features

### 🌎 3D Globe Visualization
- Interactive 3D Earth with real-time flight tracking
- Photorealistic satellite imagery with optional map view
- Animated flight paths with altitude visualization
- Weather layer integration showing global weather patterns
- Fluid, intuitive navigation with natural gestures

### ✈️ Comprehensive Flight Data
- Real-time tracking of commercial flights worldwide
- Detailed aircraft information and specifications
- Historical flight data with performance analytics
- Departure and arrival forecasts with predictive AI
- Airport information including gates, terminals, and amenities

### 🎨 Premium User Experience
- Beautiful signature themes with luxury aesthetics
- Smooth animations and micro-interactions throughout
- Dynamic, responsive UI that adapts to context
- Custom-designed iconography and typography
- Haptic feedback for intuitive interaction

### ⚙️ Advanced Features
- Offline mode with intelligent data caching
- Custom flight alerts and notifications
- Social sharing of flight information
- AR mode for identifying flights overhead
- Voice commands for hands-free operation

### 🚀 Technical Excellence
- High-performance SceneKit implementation
- Battery-efficient background updates
- Memory-optimized data management
- Multi-device synchronization
- Accessibility compliance throughout

## Getting Started

### Prerequisites
- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- CocoaPods or Swift Package Manager

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/debot.git
cd debot
```

2. Install dependencies:
```bash
pod install
# or
swift package resolve
```

3. Open the project:
```bash
open Debot.xcworkspace
```

4. Build and run the project on your device or simulator.

### API Configuration

Debot uses the AviationStack API for flight data. To use your own API key:

1. Sign up at [AviationStack](https://aviationstack.com/) to get an API key
2. Create a `Config.plist` file in the project root
3. Add your API key to the configuration file:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AviationStackAPIKey</key>
    <string>YOUR_API_KEY</string>
</dict>
</plist>
```

## Architecture

Debot follows a clean architecture approach with MVVM pattern:

```
Debot/
├── Models/           # Data models and structures
├── Views/            # SwiftUI views and components
│   ├── Components/   # Reusable UI components
│   └── Screens/      # Main application screens
├── ViewModels/       # Business logic and data transformation
├── Services/         # API and data services
├── Utilities/        # Helper functions and extensions
└── Resources/        # Assets and configuration files
```

### Key Components

- **AviationService**: Handles API communication with AviationStack
- **FlightSearchViewModel**: Manages flight search and results
- **FlightGlobeView**: Renders the 3D globe visualization
- **DebotPremiumAnimations**: Provides luxury animations and effects

## Advanced Usage

### Custom Themes

Debot offers three premium themes:

1. **Luxury Dark**: Rich, deep colors with gold accents
2. **Luxury Light**: Elegant cream and brown palette
3. **System**: Respects user's system preference with Debot styling

Themes can be switched in the app via the theme selector in the top-left corner.

### Demo Mode

When API limits are reached or for demonstration purposes, enable Demo Mode to use realistic sample data:

```swift
// Enable demo mode
viewModel.useMockData = true
```

### Custom Alerts

Set up custom flight alerts for important updates:

```swift
FlightAlertManager.shared.createAlert(for: flight, type: .departure, timeOffset: -60)
```

## Performance Optimization

Debot is optimized for performance in several ways:

1. **Memory Management**: 3D resources are loaded and unloaded as needed
2. **Efficient Networking**: Request batching and prioritization
3. **Background Processing**: Heavy tasks are performed in background threads
4. **Caching**: Intelligent caching reduces API calls and improves responsiveness
5. **Rendering Optimizations**: LOD (Level of Detail) for 3D objects based on distance

## Contributing

We welcome contributions to make Debot even better:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Credits

- Earth textures provided by NASA's [Blue Marble](https://visibleearth.nasa.gov/collection/1484/blue-marble) collection
- Airport database from [OpenFlights](https://openflights.org/data.html)
- Flight data powered by [AviationStack](https://aviationstack.com/)
- 3D visualizations built with [SceneKit](https://developer.apple.com/documentation/scenekit)
- Animations enhanced with [Lottie](https://airbnb.design/lottie/)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

© 2023 Debot Technologies. All rights reserved. 