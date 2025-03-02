import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColors) private var themeColors
    
    @Binding var query: String
    @Binding var selectedTab: Int
    
    @ObservedObject var slackViewModel: SlackViewModel
    @ObservedObject var flightViewModel: FlightSearchViewModel
    
    @State private var searchMode: Int = 0 // 0 for auto (based on selected tab), 1 for Flight, 2 for Slack
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search header
                VStack(spacing: 12) {
                    TextField("Search...", text: $query)
                        .padding(12)
                        .background(themeColors.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeColors.borderColor, lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .submitLabel(.search)
                        .onSubmit {
                            performSearch()
                        }
                    
                    // Search mode picker
                    Picker("Search in", selection: $searchMode) {
                        Text("Auto").tag(0)
                        Text("Flights").tag(1)
                        Text("Slack").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                .background(themeColors.background)
                
                // Search results
                if isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !query.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(themeColors.secondaryText)
                            .padding()
                        Text("No results found")
                            .font(.headline)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(themeColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(searchResults) { result in
                            SearchResultRow(result: result)
                                .onTapGesture {
                                    handleResultSelection(result)
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        query = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeColors.secondaryText)
                    }
                    .disabled(query.isEmpty)
                }
            }
        }
        .onAppear {
            // Set initial search mode based on selected tab
            if searchMode == 0 {
                searchMode = selectedTab == 0 ? 1 : 2
            }
        }
    }
    
    private func performSearch() {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // Determine which search to perform
        let effectiveSearchMode = searchMode == 0 ? (selectedTab == 0 ? 1 : 2) : searchMode
        
        Task {
            if effectiveSearchMode == 1 { // Flight search
                await searchFlights()
            } else { // Slack search
                await searchSlackMessages()
            }
            
            isSearching = false
        }
    }
    
    private func searchFlights() async {
        // Use the flight search functionality
        await flightViewModel.search(query: query)
        
        // Convert flight results to SearchResult format
        let results = flightViewModel.searchResults.map { flight -> SearchResult in
            return SearchResult(
                id: "flight_\(flight.id)",
                title: "\(flight.airline?.name ?? "Flight") \(flight.number ?? "Unknown")",
                subtitle: "\(flight.departure.airport ?? "Unknown") → \(flight.arrival.airport ?? "Unknown")",
                type: .flight,
                icon: "airplane",
                data: flight
            )
        }
        
        await MainActor.run {
            self.searchResults = results
        }
    }
    
    private func searchSlackMessages() async {
        // Search for messages in Slack
        let messages = await slackViewModel.searchMessages(query: query)
        
        // Convert message results to SearchResult format
        let results = messages.map { message -> SearchResult in
            return SearchResult(
                id: "slack_\(message.id)",
                title: message.userName,
                subtitle: message.text,
                type: .slackMessage,
                icon: "message",
                data: message
            )
        }
        
        await MainActor.run {
            self.searchResults = results
        }
    }
    
    private func handleResultSelection(_ result: SearchResult) {
        switch result.type {
        case .flight:
            if let flight = result.data as? Flight {
                // Set selected flight in view model and navigate to flight tab
                flightViewModel.selectedFlight = flight
                selectedTab = 0
            }
        case .slackMessage:
            if let message = result.data as? SlackMessage {
                // Set selected message in view model and navigate to slack tab
                slackViewModel.selectedMessage = message
                selectedTab = 1
            }
        }
        
        dismiss()
    }
}

// Search result type enum
enum SearchResultType {
    case flight
    case slackMessage
}

// Search result model
struct SearchResult: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let type: SearchResultType
    let icon: String
    let data: Any
}

// Search result row view
struct SearchResultRow: View {
    let result: SearchResult
    @Environment(\.themeColors) private var themeColors
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconBackground)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.headline)
                    .foregroundColor(themeColors.text)
                
                Text(result.subtitle)
                    .font(.subheadline)
                    .foregroundColor(themeColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(themeColors.secondaryText)
        }
        .padding(.vertical, 8)
    }
    
    var iconColor: Color {
        switch result.type {
        case .flight:
            return .blue
        case .slackMessage:
            return .purple
        }
    }
    
    var iconBackground: Color {
        switch result.type {
        case .flight:
            return .blue.opacity(0.2)
        case .slackMessage:
            return .purple.opacity(0.2)
        }
    }
} 