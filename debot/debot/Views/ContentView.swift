import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        RandomFlightView()
                    } label: {
                        Label("Random Flight", systemImage: "airplane")
                            .font(Theme.Typography.bodyLarge)
                    }
                } header: {
                    Text("Aviation")
                        .font(Theme.Typography.titleSmall)
                        .foregroundColor(Theme.Colors.primary)
                }
                
                Section {
                    NavigationLink(destination: ComponentShowcase()) {
                        Label("Component Showcase", systemImage: "square.grid.2x2")
                            .font(Theme.Typography.bodyLarge)
                    }
                } header: {
                    Text("Development")
                        .font(Theme.Typography.titleSmall)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .navigationTitle("Debot")
            .listStyle(.insetGrouped)
            .background(Theme.Colors.background)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.light)
} 