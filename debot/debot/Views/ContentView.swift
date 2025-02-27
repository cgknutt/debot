import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var slackViewModel: SlackViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Flight Search Tab
            FlightSearchViewContainer()
                .preferredColorScheme(.light)
                .tabItem {
                    Label("Flights", systemImage: "airplane")
                }
                .tag(0)
            
            // Slack Messages Tab
            SlackTabView(viewModel: slackViewModel)
                .preferredColorScheme(.light)
                .tabItem {
                    Label("Slack", systemImage: "message.fill")
                }
                .badge(slackViewModel.unreadCount)
                .tag(1)
        }
        .accentColor(Color.debotOrange)
    }
}

// Helper view to pass the viewModel to SlackMessagesView
struct SlackTabView: View {
    let viewModel: SlackViewModel
    
    var body: some View {
        SlackMessagesView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.light)
        .environmentObject(SlackViewModel())
} 