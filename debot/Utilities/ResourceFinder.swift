import Foundation

/// A utility class that provides methods for finding resources in a bundle
/// This avoids using methods with inconsistent parameter names like url(forResource:withExtension:) or url(forResource:ofType:)
class ResourceFinder {
    
    /// Find a URL for a resource in a bundle
    /// - Parameters:
    ///   - name: The resource name (can include directory path)
    ///   - ext: The file extension
    ///   - bundle: The bundle to search in (defaults to main bundle)
    /// - Returns: URL if found, nil otherwise
    static func findResourceURL(name: String, ext: String, in bundle: Bundle = Bundle.main) -> URL? {
        // Extract the base name without any path info
        let components = name.components(separatedBy: "/")
        let baseName = components.last ?? name
        
        // Generate possible paths
        var possiblePaths: [String] = []
        
        // Use the name as provided
        possiblePaths.append("\(name).\(ext)")
        
        // Check variants of common directory structures
        if name.contains("/") {
            // Already contains directory info, so add as is
            possiblePaths.append(name)
            possiblePaths.append("\(name).\(ext)")
        } else {
            // Add common folder patterns
            possiblePaths.append("\(name)/\(baseName).\(ext)")
            possiblePaths.append("Resources/\(name).\(ext)")
            possiblePaths.append("Resources/\(baseName).\(ext)")
            possiblePaths.append("Assets/\(name).\(ext)")
            possiblePaths.append("Assets/\(baseName).\(ext)")
            possiblePaths.append("UI/Resources/\(name).\(ext)")
            possiblePaths.append("UI/Resources/\(baseName).\(ext)")
            possiblePaths.append("UI/Resources/Fonts/\(name).\(ext)")
            possiblePaths.append("UI/Resources/Fonts/\(baseName).\(ext)")
        }
        
        // Check if any of these paths exist in the bundle
        let bundlePath = bundle.bundlePath
        for path in possiblePaths {
            let fullPath = (bundlePath as NSString).appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: fullPath) {
                print("✅ Found resource at: \(fullPath)")
                return URL(fileURLWithPath: fullPath)
            }
        }
        
        // Fallback: Try with bundle URL
        let bundleURL = bundle.bundleURL
        for path in possiblePaths {
            let fullURL = bundleURL.appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: fullURL.path) {
                print("✅ Found resource at: \(fullURL.path)")
                return fullURL
            }
        }
        
        // Final fallback: Try in the Resources directory
        if let resourcePath = bundle.resourcePath {
            for path in possiblePaths {
                let fullPath = (resourcePath as NSString).appendingPathComponent(path)
                if FileManager.default.fileExists(atPath: fullPath) {
                    print("✅ Found resource at: \(fullPath)")
                    return URL(fileURLWithPath: fullPath)
                }
            }
        }
        
        print("❌ Resource not found: \(name).\(ext)")
        return nil
    }
    
    /// Find a path for a resource in a bundle
    /// - Parameters:
    ///   - name: The resource name (can include directory path)
    ///   - ext: The file extension
    ///   - bundle: The bundle to search in (defaults to main bundle)
    /// - Returns: Path if found, nil otherwise
    static func findResourcePath(name: String, ext: String, in bundle: Bundle = Bundle.main) -> String? {
        return findResourceURL(name: name, ext: ext, in: bundle)?.path
    }
} 