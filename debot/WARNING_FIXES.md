# Warning Fixes Guide

Great job on fixing the sandbox errors! Now let's address the warnings in your project:

## 1. Run Script Phase Warning ✅

This has been fixed by the `fix_script_phase.sh` script which added proper dependency analysis settings.

## 2. Deprecated API Warnings (iOS 17.0)

### 2.1 `applicationIconBadgeNumber` Deprecation

Replace:
```swift
UIApplication.shared.applicationIconBadgeNumber = count
```

With:
```swift
UNUserNotificationCenter.current().setBadgeCount(count) { error in
    if let error = error {
        print("Error setting badge count: \(error)")
    }
}
```

### 2.2 `onChange(of:perform:)` Deprecation

Replace:
```swift
.onChange(of: value) { oldValue, newValue in
    // action
}
```

With:
```swift
.onChange(of: value) { newValue in
    // action
}
```

### 2.3 Map-related Deprecations

Replace:
```swift
Map(coordinateRegion: $region, 
    interactionModes: .all,
    showsUserLocation: true,
    userTrackingMode: .constant(.follow),
    annotationItems: annotations) { place in
    MapAnnotation(coordinate: place.coordinate) {
        // annotation content
    }
}
```

With:
```swift
Map(initialPosition: MapCameraPosition.region($region)) {
    ForEach(annotations) { place in
        Annotation(coordinate: place.coordinate) {
            // annotation content
        }
    }
    UserLocation()
}
```

## 3. Unused Variables Warnings

### 3.1 Never Mutated Variables

For variables like `components`, `depIndex`, use `let` instead of `var`:

```swift
let components = /* instead of var components = */
```

### 3.2 Unused Immutable Values

For initialization warnings like `baseAngle`, `result`, and `now`, either:
- Use the value somewhere in your code
- Assign to `_` if you don't need it:
  ```swift 
  let _ = baseAngle // instead of let baseAngle = ...
  ```
- Remove the initialization completely

## 4. Color Asset Naming Conflict

The "Primary" color asset conflicts with "primary" Color symbol:

1. Open your Assets catalog
2. Find the "Primary" color asset
3. Rename it to something like "PrimaryColor" or "AppPrimary"

## Instructions for Restarting

After making these changes:
1. Clean the build folder (Product > Clean Build Folder)
2. Restart Xcode
3. Build again to see if the warnings are resolved

Need help with any specific warning implementation? Let me know! 