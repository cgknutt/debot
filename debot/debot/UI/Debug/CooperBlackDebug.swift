import SwiftUI

/// A quick debug view to help identify the exact PostScript name for Titan One
struct TitanOneDebug: View {
    @State private var fontLoaded = false
    @State private var exactFontName = "Unknown"
    
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
                }
                .font(.system(size: 14))
                .padding(.horizontal)
            }
            
            Button("Check Available Fonts") {
                checkForTitanOne()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
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
}

#Preview {
    TitanOneDebug()
} 