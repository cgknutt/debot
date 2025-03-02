import SwiftUI

/// A debug view that displays all fonts available to the app
/// This is useful for finding the exact font name for Adobe Fonts
struct FontDebugView: View {
    @State private var searchText = ""
    @State private var selectedFontName: String?
    @State private var fontSize: CGFloat = 24
    
    // Get all font names available in the app
    private var allFontNames: [String] {
        UIFont.familyNames.flatMap { family in
            UIFont.fontNames(forFamilyName: family)
        }.sorted()
    }
    
    // Filtered font names based on search text
    private var filteredFontNames: [String] {
        if searchText.isEmpty {
            return allFontNames
        } else {
            return allFontNames.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                TextField("Search fonts", text: $searchText)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                // Font size slider
                HStack {
                    Text("Size: \(Int(fontSize))")
                        .font(.system(size: 14))
                    Slider(value: $fontSize, in: 8...72, step: 1)
                }
                .padding(.horizontal)
                
                // Font list
                List {
                    Section(header: Text("Fonts (\(filteredFontNames.count) found)")) {
                        ForEach(filteredFontNames, id: \.self) { fontName in
                            Button(action: {
                                selectedFontName = (selectedFontName == fontName) ? nil : fontName
                            }) {
                                HStack {
                                    Text(fontName)
                                        .font(Font.custom(fontName, size: fontSize))
                                    
                                    Spacer()
                                    
                                    if selectedFontName == fontName {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                
                // Titan One specific search
                Section {
                    Button(action: {
                        searchText = "titan"
                    }) {
                        Text("Search for Titan One")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                // Font details
                if let selectedFontName = selectedFontName {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Font:")
                            .font(.headline)
                        
                        Text(selectedFontName)
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("Sample:")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("ABCDEFGHIJKLM\nNOPQRSTUVWXYZ\nabcdefghijklm\nnopqrstuvwxyz\n1234567890")
                            .font(Font.custom(selectedFontName, size: fontSize))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Font Debug")
            .navigationBarItems(trailing: Button("Done") {
                // Dismiss the debug view - for integration with your app
                // Present this view modally and dismiss here
            })
        }
    }
}

#Preview {
    FontDebugView()
} 