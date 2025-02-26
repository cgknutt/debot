import SwiftUI

struct ContentView: View {
    var body: some View {
        // Use the container which safely handles MainActor isolation
        FlightSearchViewContainer()
            .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.light)
} 