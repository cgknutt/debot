import Foundation
import SwiftUI

// Import ThemeMode from Views module
// We'll use a type alias instead of redefining the enum
// This assumes ThemeMode is available through module structure

@MainActor
class FlightSearchViewModel: ObservableObject {
    private let aviationService = AviationService()
    // Using private variables with AppStorage
    private var storage = UserDefaults.standard
    
    // Private backing properties
    private var _useMockData: Bool {
        get { storage.bool(forKey: "useMockData") }
        set { 
            storage.set(newValue, forKey: "useMockData")
            // Don't call refreshData here to avoid race conditions during initialization
        }
    }
    
    // Public property to access and modify useMockData
    var useMockData: Bool {
        get { _useMockData }
        set { 
            if _useMockData != newValue {
                _useMockData = newValue 
                // Refresh data when the setting changes, but only after a small delay
                // to ensure UI remains responsive
                Task { 
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    refreshData() 
                }
            }
        }
    }
    
    @Published var searchText = ""
    @Published var flights: [Flight] = []
    @Published var randomFlight: Flight?
    @Published var isLoading = false
    @Published var error: String?
    @Published var remainingRequests: Int = 100
    @Published var searchTip: String = "Search by flight number (e.g., 'UA123') or airports (e.g., 'SFO LAX')"
    @Published var isSearchMode: Bool = false
    
    // Properties used in FlightSearchView.swift
    @Published var searchQuery: String = ""
    @Published var searchResults: [Flight] = []
    @Published var searched: Bool = false
    @Published var themeMode = ThemeMode.system // Using the enum from FlightSearchView
    @Published var systemColorScheme: ColorScheme = .dark
    
    // ViewFlight versions of the flight data for compatibility with FlightSearchView
    @Published var viewFlights: [ViewFlight] = []
    @Published var viewRandomFlight: ViewFlight?
    
    // Filter states (simplified for free tier)
    @Published var showOnlyDepartures = false
    @Published var showOnlyArrivals = false
    
    // Search parameters
    @Published var searchParameters = AviationService.SearchParameters()
    
    // Tutorial/onboarding state
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @Published var showTutorial = false
    
    // Filtered flights based on user preferences
    var filteredFlights: [Flight] {
        var filtered = flights
        
        if showOnlyDepartures {
            filtered = filtered.filter { $0.departure.airport != nil }
        }
        
        if showOnlyArrivals {
            filtered = filtered.filter { $0.arrival.airport != nil }
        }
        
        return filtered
    }
    
    // Add a computed property to convert Flight array to ViewFlight array
    var convertedSearchResults: [ViewFlight] {
        return searchResults.map { $0.toViewFlight() }
    }
    
    var convertedRandomFlight: ViewFlight? {
        return randomFlight?.toViewFlight()
    }
    
    init() {
        // Check if the user has seen the tutorial
        if !hasSeenTutorial {
            showTutorial = true
            hasSeenTutorial = true
        }
        
        // Load a random flight when initializing
        // Using Task.detached to ensure it doesn't block the main thread
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // Small delay for UI to load first
            await fetchRandomFlight()
        }
    }
    
    func toggleMockData() {
        useMockData.toggle() // This will call the setter which calls refreshData()
    }
    
    func fetchRandomFlight() async {
        isLoading = true
        error = nil
        
        do {
            if _useMockData {
                // Use mock data when API limit is reached or for testing
                if let flight = MockFlightDataService.shared.getRandomFlight() {
                    randomFlight = flight
                    viewRandomFlight = flight.toViewFlight() // Convert to ViewFlight
                } else {
                    error = "No sample flights available"
                }
            } else {
                // Try to get a flight from cache first
                if let cachedFlight = FlightCache.shared.getRecentRandomFlight() {
                    randomFlight = cachedFlight
                    viewRandomFlight = cachedFlight.toViewFlight() // Convert to ViewFlight
                } else {
                    // If not in cache, fetch from API
                    randomFlight = try await aviationService.getRandomFlight()
                    
                    // Convert to ViewFlight
                    if let flight = randomFlight {
                        viewRandomFlight = flight.toViewFlight()
                        
                        // Cache the result
                        FlightCache.shared.addRecentRandomFlight(flight)
                    }
                }
            }
            
            // Update remaining requests
            remainingRequests = _useMockData ? 100 : (100 - aviationService.requestCount)
        } catch {
            // API error - switch to mock data if needed
            if error.localizedDescription.contains("subscription") || 
               error.localizedDescription.contains("limit") {
                _useMockData = true
                if let flight = MockFlightDataService.shared.getRandomFlight() {
                    randomFlight = flight
                    viewRandomFlight = flight.toViewFlight() // Convert to ViewFlight
                } else {
                    self.error = "No flights available. Please try again later."
                }
            } else {
                self.error = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    // Public function to be called from the view
    func searchFlights() {
        Task {
            // Update searchText from searchQuery for compatibility
            searchText = searchQuery
            await searchFlightsAsync()
        }
    }
    
    // Renamed the async version to avoid recursion
    private func searchFlightsAsync() async {
        guard !searchText.isEmpty else {
            // If search is cleared, show random flight
            isSearchMode = false
            flights = []
            viewFlights = [] // Clear ViewFlights
            searched = false // Reset searched flag
            await fetchRandomFlight()
            return
        }
        
        // Synchronize searchText with searchQuery for compatibility with FlightSearchView
        searchQuery = searchText
        
        // Set these flags immediately to ensure UI is updated
        isSearchMode = true
        isLoading = true
        error = nil
        searched = true // Set to true as search is initiated
        
        // Parse search text to determine what the user is looking for
        parseSearchText()
        
        print("Searching for: \(searchText) with params: \(searchParameters)")
        
        do {
            // Check cache first
            if let cachedFlights = FlightCache.shared.getCachedFlights(for: searchText) {
                flights = cachedFlights
                searchResults = cachedFlights // Update searchResults for compatibility
                viewFlights = cachedFlights.map { $0.toViewFlight() } // Convert to ViewFlights
                print("Using cached results for '\(searchText)'")
            } else if _useMockData {
                // Use mock data when API limit is reached or for testing
                flights = MockFlightDataService.shared.searchFlights(query: searchText)
                searchResults = flights // Update searchResults for compatibility
                viewFlights = flights.map { $0.toViewFlight() } // Convert to ViewFlights
                
                // Cache mock results too
                FlightCache.shared.cacheFlights(flights, for: searchText)
            } else {
                // If not in cache, fetch from API
                flights = try await aviationService.searchFlights(parameters: searchParameters)
                searchResults = flights // Update searchResults for compatibility
                viewFlights = flights.map { $0.toViewFlight() } // Convert to ViewFlights
                
                // Cache the results
                FlightCache.shared.cacheFlights(flights, for: searchText)
            }
            
            // Mark as searched for the UI
            searched = true
            
            // Update remaining requests
            remainingRequests = _useMockData ? 100 : (100 - aviationService.requestCount)
            
            // Provide feedback if no results
            if flights.isEmpty {
                searchTip = "No flights found. Try searching for active flights using flight number or airport codes (e.g., 'SFO LAX')"
            }
        } catch {
            // API error - switch to mock data if needed
            if error.localizedDescription.contains("subscription") ||
               error.localizedDescription.contains("limit") {
                _useMockData = true
                flights = MockFlightDataService.shared.searchFlights(query: searchText)
                searchResults = flights // Update searchResults for compatibility
                viewFlights = flights.map { $0.toViewFlight() } // Convert to ViewFlights
                
                if flights.isEmpty {
                    searchTip = "No flights found. Try searching for a different airport or flight number."
                }
            } else {
                self.error = error.localizedDescription
                // Provide more helpful error messages for free tier limitations
                if error.localizedDescription.contains("subscription") {
                    searchTip = "Free tier tip: Try searching for active flights only, using airport codes or flight numbers"
                }
            }
        }
        
        isLoading = false
    }
    
    private func parseSearchText() {
        // Reset search parameters
        searchParameters = AviationService.SearchParameters()
        
        let searchComponents = searchText.components(separatedBy: .whitespaces)
            .map { $0.uppercased().trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        
        // First, look for flight numbers (usually 2-6 characters followed by 1-4 digits)
        if let flightNumber = searchComponents.first(where: { $0.contains(where: \.isNumber) }) {
            searchParameters.flightNumber = flightNumber
            return // If we found a flight number, don't look for airports
        }
        
        // If no flight number, look for airport codes (3-letter IATA codes)
        let airportCodes = searchComponents.filter { $0.count == 3 && $0.uppercased() == $0 }
        if airportCodes.count >= 1 {
            searchParameters.departureAirport = airportCodes[0]
        }
        if airportCodes.count >= 2 {
            searchParameters.arrivalAirport = airportCodes[1]
        }
    }
    
    // Add getRandomFlight method that can be called directly from the view
    func getRandomFlight() {
        Task {
            await fetchRandomFlight()
        }
    }
    
    private func refreshData() {
        // Clear any existing data - this is fine on the main thread
        flights = []
        randomFlight = nil
        
        // Use Task.detached for background work to avoid UI blocking
        Task.detached {
            // Capture the current state
            let currentSearchMode = await self.isSearchMode
            let currentSearchText = await self.searchText
            
            // Perform appropriate data refresh on background thread
            if currentSearchMode && !currentSearchText.isEmpty {
                await self.searchFlightsAsync()
            } else {
                await self.fetchRandomFlight()
            }
        }
    }
} 
