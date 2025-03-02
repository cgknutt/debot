import SwiftUI

/// A quick debug view to help identify the exact PostScript name for Titan One
struct TitanOneDebug: View {
    @State private var fontLoaded = false
    @State private var exactFontName = "Unknown"
    @State private var loadMethod = "System Registry"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Titan One Font Debugger")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 20)
            
            Divider()
            
            // Check if Titan One font loads correctly
            Group {
                Text("Status: \(fontLoaded ? "✅ LOADED" : "❌ NOT FOUND")")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(fontLoaded ? .green : .red)
                
                Text("PostScript Name: \(exactFontName)")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                
                Text("Load Method: \(loadMethod)")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
            
            if fontLoaded {
                Text("Sample Text in Titan One")
                    .font(.system(size: 18))
                
                Text("The quick brown fox")
                    .font(Font.custom(exactFontName, size: 28))
                
                Text("ABCDEFGHIJKLM")
                    .font(Font.custom(exactFontName, size: 24))
                
                Text("1234567890")
                    .font(Font.custom(exactFontName, size: 24))
            } else {
                Text("Font Not Found")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.red)
                
                Text("Possible reasons:")
                    .font(.headline)
                    .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Font file may not be included in the project")
                    Text("• Font may not be properly registered in Info.plist")
                    Text("• Font name may be different than expected")
                    Text("• Bundle may not be finding the font resource")
                    Text("• Path in UIAppFonts may be incorrect")
                }
                .font(.system(size: 14))
                .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                Button("Check Fonts") {
                    checkForTitanOne()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Try Manual Load") {
                    tryManualFontLoad()
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.top)
            
            Spacer()
        }
        .padding()
        .onAppear {
            checkForTitanOne()
        }
    }
    
    private func checkForTitanOne() {
        // Try common naming patterns for Titan One
        let fontNames = [
            "TitanOne-Regular",
            "TitanOne",
            "Titan One",
            "Titan-One",
            "TitanOneRegular"
        ]
        
        fontLoaded = false
        loadMethod = "System Registry"
        
        for name in fontNames {
            if let _ = UIFont(name: name, size: 12) {
                fontLoaded = true
                exactFontName = name
                print("Found Titan One font: \(name)")
                break
            }
        }
        
        if !fontLoaded {
            print("Titan One font not found with any expected name")
            
            // Print all available fonts for debugging
            let families = UIFont.familyNames.sorted()
            for family in families {
                print("Font Family: \(family)")
                let names = UIFont.fontNames(forFamilyName: family)
                for name in names {
                    print("   Font: \(name)")
                    if name.lowercased().contains("titan") {
                        print("   ✅ FOUND TITAN FONT: \(name)")
                        fontLoaded = true
                        exactFontName = name
                    }
                }
            }
        }
    }
    
    private func tryManualFontLoad() {
        // Try to manually register the font from the Assets folder
        if let fontURL = ResourceFinder.findResourceURL(name: "Assets/Fonts/TitanOne-Regular", ext: "ttf") {
            do {
                let data = try Data(contentsOf: fontURL)
                var success = false
                
                // Use the modern non-deprecated API for font registration
                if #available(iOS 18.0, *) {
                    // For iOS 18 and above, use the new API
                    let fontDescriptors = CTFontManagerCreateFontDescriptorsFromData(data as CFData)
                    if let descriptors = fontDescriptors as? [CTFontDescriptor], !descriptors.isEmpty {
                        print("✅ Successfully registered font using modern API")
                        success = true
                    }
                } else {
                    // For earlier iOS versions, use direct URL registration
                    var error: Unmanaged<CFError>?
                    if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                        print("✅ Successfully registered font from URL")
                        success = true
                    }
                }
                
                if success {
                    loadMethod = "Manual Registration from Resources"
                    
                    // Check if registration worked
                    let fontName = "TitanOne-Regular"
                    if let _ = UIFont(name: fontName, size: 12) {
                        fontLoaded = true
                        exactFontName = fontName
                    } else {
                        // Try to find it with a different name after registration
                        checkForTitanOne()
                    }
                } else {
                    print("❌ Failed to register font from Resources")
                    loadMethod = "Failed Manual Registration"
                }
            } catch {
                print("❌ Error loading font data: \(error)")
                loadMethod = "Error: \(error.localizedDescription)"
            }
        } else {
            print("❌ Font file not found in Resources")
            loadMethod = "Font File Not Found in Resources"
            
            // Try other potential paths
            let potentialPaths = [
                "TitanOne-Regular",
                "Fonts/TitanOne-Regular",
                "Assets/Fonts/TitanOne-Regular",
                "../Assets/Fonts/TitanOne-Regular",
                "debot/Assets/Fonts/TitanOne-Regular"
            ]
            
            for path in potentialPaths {
                // Use Bundle.main.path instead of url since we only need to check existence
                if ResourceFinder.findResourcePath(name: path, ext: "ttf") != nil {
                    print("✅ Found font at path: \(path)")
                    loadMethod = "Found at: \(path)"
                    break
                }
            }
        }
    }
}

#Preview {
    TitanOneDebug()
}

/// A quick debug view to help identify the exact PostScript name for Cooper Black
struct CooperBlackDebug: View {
    @State private var fontLoaded = false
    @State private var exactFontName = "Unknown"
    @State private var loadMethod = "System Registry"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Cooper Black Font Debugger")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 20)
            
            Divider()
            
            // Check if Cooper Black font loads correctly
            Group {
                Text("Status: \(fontLoaded ? "✅ LOADED" : "❌ NOT FOUND")")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(fontLoaded ? .green : .red)
                
                Text("PostScript Name: \(exactFontName)")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                
                Text("Load Method: \(loadMethod)")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
            
            if fontLoaded {
                Text("Sample Text in Cooper Black")
                    .font(.system(size: 18))
                
                Text("The quick brown fox")
                    .font(Font.custom(exactFontName, size: 28))
                
                Text("ABCDEFGHIJKLM")
                    .font(Font.custom(exactFontName, size: 24))
                
                Text("1234567890")
                    .font(Font.custom(exactFontName, size: 24))
            } else {
                Text("Font Not Found")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.red)
                
                Text("Possible reasons:")
                    .font(.headline)
                    .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Font file may not be included in the project")
                    Text("• Font may not be properly registered in Info.plist")
                    Text("• Font name may be different than expected")
                    Text("• Bundle may not be finding the font resource")
                    Text("• Path in UIAppFonts may be incorrect")
                }
                .font(.system(size: 14))
                .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                Button("Check Fonts") {
                    checkForCooperBlack()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Try Manual Load") {
                    tryManualFontLoad()
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.top)
            
            Spacer()
        }
        .padding()
        .onAppear {
            checkForCooperBlack()
        }
    }
    
    private func checkForCooperBlack() {
        // Try common naming patterns for Cooper Black
        let fontNames = [
            "CooperBlack",
            "Cooper-Black",
            "Cooper Black",
            "CooperBlack-Regular",
            "CooperBlackRegular"
        ]
        
        fontLoaded = false
        loadMethod = "System Registry"
        
        for name in fontNames {
            if let _ = UIFont(name: name, size: 12) {
                fontLoaded = true
                exactFontName = name
                print("Found Cooper Black font: \(name)")
                break
            }
        }
        
        if !fontLoaded {
            print("Cooper Black font not found with any expected name")
            
            // Print all available fonts for debugging
            let families = UIFont.familyNames.sorted()
            for family in families {
                print("Font Family: \(family)")
                let names = UIFont.fontNames(forFamilyName: family)
                for name in names {
                    print("   Font: \(name)")
                    if name.lowercased().contains("cooper") {
                        print("   ✅ FOUND COOPER FONT: \(name)")
                        fontLoaded = true
                        exactFontName = name
                    }
                }
            }
        }
    }
    
    private func tryManualFontLoad() {
        // Try to manually register the font from the Resources folder
        let fontFilename = "CooperBlack"
        let fontExtension = "ttf"
        
        // Check if the font file exists in various possible locations
        let potentialPaths = [
            "UI/Resources/Fonts/\(fontFilename)",
            "Resources/Fonts/\(fontFilename)",
            "Assets/Fonts/\(fontFilename)",
            "\(fontFilename)"
        ]
        
        var success = false
        
        for path in potentialPaths {
            if let fontURL = ResourceFinder.findResourceURL(name: path, ext: fontExtension) {
                // Explicitly check if the file exists at the URL path
                if FileManager.default.fileExists(atPath: fontURL.path) {
                    // Attempt to read data from the URL
                    do {
                        let data = try Data(contentsOf: fontURL)
                        
                        // Use the modern non-deprecated API for font registration
                        if #available(iOS 18.0, *) {
                            // For iOS 18 and above, use the new API
                            let fontDescriptors = CTFontManagerCreateFontDescriptorsFromData(data as CFData)
                            if let descriptors = fontDescriptors as? [CTFontDescriptor], !descriptors.isEmpty {
                                print("✅ Successfully registered Cooper Black font using modern API")
                                success = true
                            }
                        } else {
                            // For earlier iOS versions, use direct URL registration
                            var error: Unmanaged<CFError>?
                            if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                                print("✅ Successfully registered Cooper Black font from URL")
                                success = true
                            }
                        }
                        
                        if success {
                            loadMethod = "Manual Registration from \(path).\(fontExtension)"
                            checkForCooperBlack() // Check if registration worked
                            return
                        } else {
                            print("❌ Failed to register font from \(path)")
                        }
                    } catch {
                        print("❌ Could not read data from font URL at path: \(path) - Error: \(error)")
                    }
                } else {
                    print("❌ File does not exist at URL path: \(fontURL.path)")
                }
            } else {
                print("❌ Could not create URL for path: \(path)")
            }
        }
        
        // If we got here, none of the paths worked
        loadMethod = "Font File Not Found in Any Location"
        print("❌ Cooper Black font file not found in any of the expected locations")
    }
}

#Preview {
    CooperBlackDebug()
} 